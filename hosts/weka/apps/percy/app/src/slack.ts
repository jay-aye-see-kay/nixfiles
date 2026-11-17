// Percy's Slack reply UI, built on Slack's agent APIs:
// - agents.sessions.setStatus marks the thread as an agent session that is
//   "processing" (Slack's loading indicator plus a stop button), and
//   chat.stopStream hands it back as "active" when the reply is done.
// - chat.startStream/appendStream/stopStream stream one message that holds
//   the reply's markdown interleaved with task cards (timeline mode): one card
//   per tool call, updated in place from in_progress to complete or error.
// - The finished message ends with feedback buttons (context_actions).
// @see: https://docs.slack.dev/ai/developing-agents
// @see: https://docs.slack.dev/reference/methods/chat.startStream
import type { AgentSessionEvent } from "@earendil-works/pi-coding-agent";
import type { AnyChunk, KnownBlock, TaskUpdateChunk } from "@slack/types";
import type { WebClient } from "@slack/web-api";

const log = (...args: unknown[]) => console.log(new Date().toISOString(), ...args);

// chat.appendStream is tier 4 (100+/min); one flush a second leaves headroom
// for the occasional rollover (startStream/stopStream are tier 2, 20+/min).
const FLUSH_INTERVAL_MS = 1000;
// Per-stream limits: 12,000 markdown chars, 50 tasks, 10 minutes. Roll over
// to a fresh streamed message a little before each one.
const STREAM_MARKDOWN_LIMIT = 11_000;
const STREAM_TASK_LIMIT = 45;
const STREAM_LIFETIME_MS = 9 * 60 * 1000;
const TASK_TITLE_MAX = 120;
const TASK_TEXT_MAX = 600;

export const FEEDBACK_ACTION_ID = "percy_feedback";

export interface ReplyTarget {
	channel: string;
	threadTs: string;
	/** The asker: streams outside DMs need a recipient user and team. */
	userId: string;
	teamId: string;
	/** Session title, used only when Slack creates the session. */
	title: string;
}

type Task = Omit<TaskUpdateChunk, "type">;

function slackError(err: unknown): string {
	return (err as { data?: { error?: string } })?.data?.error ?? (err instanceof Error ? err.message : String(err));
}

const clip = (s: string, max: number) => (s.length > max ? `${s.slice(0, max - 1)}…` : s);

/**
 * One streamed reply in a thread. Text and task updates are queued and
 * flushed at most once a second; consecutive markdown merges and repeated
 * updates to one task collapse to the latest. If streaming fails outright,
 * the reply falls back to chat.postMessage with the accumulated text.
 */
export class SlackReply {
	private pending: AnyChunk[] = [];
	private streamTs: string | undefined;
	private streamStartedAt = 0;
	private streamMarkdown = 0;
	private streamTasks = new Set<string>();
	private timer: NodeJS.Timeout | undefined;
	private chain: Promise<void> = Promise.resolve();
	private broken = false;
	private finished = false;
	/** Everything written, for the postMessage fallback. */
	private fullText = "";
	stopped = false;

	constructor(
		private readonly web: WebClient,
		private readonly target: ReplyTarget,
		private readonly onStoppedByUser: () => void,
	) {}

	/** Mark the thread's agent session as processing. Best effort. */
	async begin(): Promise<void> {
		const { channel, threadTs, userId, title } = this.target;
		try {
			await this.web.agents.sessions.setStatus({
				channel_id: channel,
				thread_ts: threadTs,
				status: "processing",
				title: clip(title, 200),
				initiator_user_id: userId,
			});
		} catch (err) {
			// Workspaces without agent sessions: the legacy status line still
			// shows a loading indicator, and clears when the reply posts.
			log(`agents.sessions.setStatus failed (${slackError(err)}), using assistant.threads.setStatus`);
			await this.web.assistant.threads
				.setStatus({ channel_id: channel, thread_ts: threadTs, status: "is thinking…" })
				.catch((e) => log(`assistant.threads.setStatus failed: ${slackError(e)}`));
		}
	}

	text(delta: string): void {
		if (!delta || this.finished) return;
		this.fullText += delta;
		const last = this.pending.at(-1);
		if (last?.type === "markdown_text") last.text += delta;
		else this.pending.push({ type: "markdown_text", text: delta });
		this.schedule();
	}

	task(task: Task): void {
		if (this.finished) return;
		const chunk: TaskUpdateChunk = {
			type: "task_update",
			...task,
			title: clip(task.title, TASK_TITLE_MAX),
			...(task.details !== undefined && { details: clip(task.details, TASK_TEXT_MAX) }),
			...(task.output !== undefined && { output: clip(task.output, TASK_TEXT_MAX) }),
		};
		const at = this.pending.findIndex((c) => c.type === "task_update" && c.id === task.id);
		if (at >= 0) this.pending[at] = chunk;
		else this.pending.push(chunk);
		this.schedule();
	}

	/** Has any reply text been written (as opposed to only task cards)? */
	get hasText(): boolean {
		return this.fullText.trim().length > 0;
	}

	/** Flush everything and finalise the message with feedback buttons. */
	async finish(): Promise<void> {
		if (this.finished) return;
		this.finished = true;
		clearTimeout(this.timer);
		await this.enqueue(async () => {
			if (!this.broken && !this.stopped) {
				try {
					await this.flushNow();
					if (this.streamTs) {
						await this.web.chat.stopStream({
							channel: this.target.channel,
							ts: this.streamTs,
							blocks: [feedbackBlock()],
							session_status: "active",
						});
						return;
					}
				} catch (err) {
					log(`stream finish failed: ${slackError(err)}`);
					this.broken = true;
				}
			}
			if (this.stopped) {
				await this.setActive();
				return;
			}
			// Streaming never worked (or broke): post the text the old way
			await this.web.chat.postMessage({
				channel: this.target.channel,
				thread_ts: this.target.threadTs,
				text: this.fullText.trim() || "…",
				blocks: [{ type: "markdown", text: clip(this.fullText.trim() || "…", 12_000) }, feedbackBlock()],
			});
			await this.setActive();
		});
	}

	private async setActive(): Promise<void> {
		await this.web.agents.sessions
			.setStatus({ channel_id: this.target.channel, thread_ts: this.target.threadTs, status: "active" })
			.catch(() => undefined);
	}

	private schedule(): void {
		if (this.timer || this.broken || this.stopped) return;
		// The first chunk starts the stream right away so the reply appears at once
		const delay = this.streamTs ? FLUSH_INTERVAL_MS : 0;
		this.timer = setTimeout(() => {
			this.timer = undefined;
			void this.enqueue(() => this.flushNow());
		}, delay);
	}

	private enqueue(job: () => Promise<void>): Promise<void> {
		const run = this.chain.then(job).catch((err) => {
			log(`stream flush failed: ${slackError(err)}`);
			this.broken = true;
		});
		this.chain = run;
		return run;
	}

	private async flushNow(): Promise<void> {
		while (this.pending.length > 0 && !this.broken && !this.stopped) {
			if (this.streamTs && Date.now() - this.streamStartedAt > STREAM_LIFETIME_MS) await this.rollover();
			const batch = this.takeBatch();
			if (batch.length === 0) {
				// The next chunk does not fit in this stream: start another
				if (!this.streamTs) throw new Error("chunk fits in no stream");
				await this.rollover();
				continue;
			}
			try {
				await this.send(batch);
			} catch (err) {
				const code = slackError(err);
				if (code === "stopped_by_user") {
					this.stopped = true;
					this.onStoppedByUser();
					return;
				}
				if (code === "message_not_in_streaming_state" && this.streamTs) {
					// Slack closed the stream (timeout): carry on in a fresh message
					this.pending.unshift(...batch);
					this.resetStream();
					continue;
				}
				throw err;
			}
		}
	}

	/**
	 * Take as many pending chunks as fit in the current stream's budgets,
	 * splitting markdown at a line break when only part of it fits.
	 */
	private takeBatch(): AnyChunk[] {
		const batch: AnyChunk[] = [];
		let markdown = this.streamMarkdown;
		const tasks = new Set(this.streamTasks);
		while (this.pending.length > 0) {
			const chunk = this.pending[0]!;
			if (chunk.type === "markdown_text") {
				const room = STREAM_MARKDOWN_LIMIT - markdown;
				if (chunk.text.length > room) {
					const window = chunk.text.slice(0, room);
					const cut = window.lastIndexOf("\n");
					if (cut > 0 && (batch.length > 0 || markdown > 0 || cut > room / 2)) {
						batch.push({ type: "markdown_text", text: chunk.text.slice(0, cut) });
						chunk.text = chunk.text.slice(cut + 1);
						markdown += cut;
					} else if (markdown === 0 && batch.length === 0) {
						// One unbroken run longer than a whole stream: hard cut
						batch.push({ type: "markdown_text", text: window });
						chunk.text = chunk.text.slice(room);
						markdown += room;
					}
					break;
				}
				markdown += chunk.text.length;
			} else if (chunk.type === "task_update" && !tasks.has(chunk.id)) {
				if (tasks.size >= STREAM_TASK_LIMIT) break;
				tasks.add(chunk.id);
			}
			batch.push(this.pending.shift()!);
		}
		return batch;
	}

	private async send(batch: AnyChunk[]): Promise<void> {
		const { channel, threadTs, userId, teamId } = this.target;
		if (!this.streamTs) {
			const res = await this.web.chat.startStream({
				channel,
				thread_ts: threadTs,
				recipient_user_id: userId,
				recipient_team_id: teamId,
				task_display_mode: "timeline",
				chunks: batch,
			});
			this.streamTs = res.ts;
			this.streamStartedAt = Date.now();
		} else {
			await this.web.chat.appendStream({ channel, ts: this.streamTs, chunks: batch });
		}
		for (const c of batch) {
			if (c.type === "markdown_text") this.streamMarkdown += c.text.length;
			if (c.type === "task_update") this.streamTasks.add(c.id);
		}
	}

	/** Forget the current stream, so the next send starts a fresh one with fresh budgets. */
	private resetStream(): void {
		this.streamTs = undefined;
		this.streamMarkdown = 0;
		this.streamTasks = new Set();
	}

	/** Close the current streamed message and let the next flush start another. */
	private async rollover(): Promise<void> {
		if (!this.streamTs) return;
		const ts = this.streamTs;
		this.resetStream();
		await this.web.chat
			.stopStream({ channel: this.target.channel, ts, session_status: "processing" })
			.catch((err) => log(`stream rollover stop failed: ${slackError(err)}`));
	}
}

function feedbackBlock(): KnownBlock {
	return {
		type: "context_actions",
		elements: [
			{
				type: "feedback_buttons",
				action_id: FEEDBACK_ACTION_ID,
				positive_button: {
					text: { type: "plain_text", text: "Good response" },
					accessibility_label: "Mark this response as good",
					value: "positive",
				},
				negative_button: {
					text: { type: "plain_text", text: "Bad response" },
					accessibility_label: "Mark this response as bad",
					value: "negative",
				},
			},
		],
	};
}

/** A short, human title for one tool call. */
export function describeToolCall(toolName: string, args: unknown): string {
	const a = (args ?? {}) as Record<string, unknown>;
	const s = (k: string) => (typeof a[k] === "string" || typeof a[k] === "number" ? String(a[k]) : "");
	switch (toolName) {
		case "read":
			return `Reading ${s("path")}`;
		case "grep":
			return `Searching for “${s("pattern")}”${s("path") ? ` in ${s("path")}` : ""}`;
		case "find":
			return `Finding ${s("pattern")}${s("path") ? ` in ${s("path")}` : ""}`;
		case "ls":
			return `Listing ${s("path") || "/"}`;
		case "codemode":
			return "Running a script";
		case "journal": {
			const parts = [s("unit") || "all units", s("since") && `since ${s("since")}`, s("until") && `until ${s("until")}`];
			if (s("priority")) parts.push(`${s("priority")}+`);
			if (s("grep")) parts.push(`matching /${s("grep")}/`);
			return `Reading logs: ${parts.filter(Boolean).join(", ")}`;
		}
		case "units":
			return `Listing services${s("pattern") ? ` matching ${s("pattern")}` : ""}${s("state") ? ` (${s("state")})` : ""}`;
		case "status":
			return `Checking ${s("unit")}`;
		case "logs":
			return `Searching logs: ${s("query")}${s("since") ? ` since ${s("since")}` : ""}`;
		case "logLabels":
			return s("label") ? `Listing log ${s("label")} values` : "Listing log labels";
		case "query":
			return `Querying metrics: ${s("query")}`;
		case "queryRange":
			return `Graphing metrics: ${s("query")}${s("since") ? ` since ${s("since")}` : ""}`;
		case "metrics":
			return `Finding metrics${s("match") ? ` matching ${s("match")}` : ""}`;
		case "alerts":
			return "Checking alerts";
		case "targets":
			return "Checking scrape targets";
		default: {
			const scalars = Object.entries(a)
				.filter(([, v]) => typeof v === "string" || typeof v === "number")
				.map(([k, v]) => `${k}=${String(v)}`);
			return scalars.length ? `${toolName} ${scalars.join(" ")}` : toolName;
		}
	}
}

/** First text of a tool result, for a card's output line. */
function resultText(result: unknown): string {
	const content = (result as { content?: { type: string; text?: string }[] } | undefined)?.content;
	const text = content?.find((c) => c.type === "text")?.text ?? "";
	return text.trim();
}

/**
 * Turn a pi session's events into reply text and task cards. A codemode
 * script is one card; the tools it calls show as its steps (details), and
 * its title follows the latest of them, so one model turn is one card.
 */
export function presentEvents(reply: SlackReply): (event: AgentSessionEvent) => void {
	const cards = new Map<string, { title: string; steps: string[] }>();
	let wroteText = false;
	let newBlock = false;

	return (event) => {
		switch (event.type) {
			case "message_update": {
				const e = event.assistantMessageEvent;
				if (e.type === "text_start") newBlock = true;
				if (e.type === "text_delta" && e.delta) {
					// Separate text from successive model turns with a blank line
					if (newBlock && wroteText) reply.text("\n\n");
					newBlock = false;
					wroteText = true;
					reply.text(e.delta);
				}
				return;
			}
			case "tool_execution_start": {
				const title = describeToolCall(event.toolName, event.args);
				if (event.parentToolCallId) {
					const parent = cards.get(event.parentToolCallId);
					if (!parent) return;
					parent.title = title;
					parent.steps.push(title);
					reply.task({ id: event.parentToolCallId, title, status: "in_progress", details: parent.steps.join("\n") });
					return;
				}
				cards.set(event.toolCallId, { title, steps: [] });
				reply.task({ id: event.toolCallId, title, status: "in_progress" });
				return;
			}
			case "tool_execution_end": {
				if (event.parentToolCallId) {
					// A failed step shows on its parent card's details
					const parent = cards.get(event.parentToolCallId);
					if (parent && event.isError) {
						const i = parent.steps.length - 1;
						if (i >= 0) parent.steps[i] += " (failed)";
					}
					return;
				}
				const card = cards.get(event.toolCallId);
				if (!card) return;
				const details = card.steps.length > 1 ? card.steps.join("\n") : undefined;
				// Codemode cards get a summary title once the script is done
				const title =
					event.toolName === "codemode" && card.steps.length > 1 ? `Ran ${card.steps.length} lookups` : card.title;
				const output = event.isError ? resultText(event.result).replace(/^Script failed\s*/, "") : undefined;
				reply.task({
					id: event.toolCallId,
					title,
					status: event.isError ? "error" : "complete",
					...(details && { details }),
					...(output && { output }),
				});
				return;
			}
			default:
				return;
		}
	};
}
