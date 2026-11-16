// Percy: a read-only pi agent living in Slack's #percy channel, one context
// window per thread. Slack Socket Mode only (outbound WebSocket), so nothing
// on weka is exposed. Runs as a systemd service with its own state dir.
import { loadConfig, Percy } from "./agent.js";
import { FEEDBACK_ACTION_ID, presentEvents, SlackReply } from "./slack.js";
import { SocketModeClient } from "@slack/socket-mode";
import { WebClient } from "@slack/web-api";
import { appendFile } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

const SWEEP_INTERVAL_MS = 5 * 60 * 1000;
const SESSION_TTL_MS = 60 * 60 * 1000;

const log = (...args: unknown[]) => console.log(new Date().toISOString(), ...args);

interface MessageEvent {
	channel?: string;
	ts?: string;
	thread_ts?: string;
	text?: string;
	subtype?: string;
	bot_id?: string;
	user?: string;
	team?: string;
	user_team?: string;
}

/**
 * Resolve a Slack user ID to a display name, cached (needs the users:read
 * scope; falls back to the raw ID so a missing scope degrades gracefully).
 */
const userNames = new Map<string, string>();
async function userName(web: WebClient, userId: string): Promise<string> {
	let name = userNames.get(userId);
	if (!name) {
		try {
			const info = await web.users.info({ user: userId });
			const profile = info.user?.profile;
			name = profile?.display_name || profile?.real_name || info.user?.name || userId;
		} catch {
			name = userId;
		}
		userNames.set(userId, name);
	}
	return name;
}

/** Local send time, e.g. "Mon 16 Nov 14:05", so percy can resolve "today" or "this afternoon". */
export function sentAt(ts: string | undefined): string {
	const d = ts ? new Date(Number(ts) * 1000) : new Date();
	const fmt = new Intl.DateTimeFormat("en-AU", {
		weekday: "short",
		day: "numeric",
		month: "short",
		hour: "2-digit",
		minute: "2-digit",
		hourCycle: "h23",
	});
	const p = Object.fromEntries(fmt.formatToParts(d).map((x) => [x.type, x.value]));
	return `${p.weekday} ${p.day} ${p.month} ${p.hour}:${p.minute}`;
}

/**
 * Label a message so percy can tell speakers apart and knows when it was
 * sent: "[Name · Mon 16 Nov 14:05] text", with mentions as @Name. The time
 * rides on the message rather than the system prompt, which keeps the prompt
 * cacheable.
 */
export async function labelMessage(web: WebClient, userId: string, text: string, ts?: string): Promise<string> {
	const mention = /<@([A-Z0-9]+)>/g;
	const needs = [userId, ...Array.from(text.matchAll(mention), (m) => m[1]!)];
	await Promise.all(needs.map((id) => userName(web, id)));
	const labeled = text.replace(mention, (_all, id: string) => `@${userNames.get(id) ?? id}`);
	return `[${userNames.get(userId) ?? userId} · ${sentAt(ts)}] ${labeled}`;
}

/** Find the channel ID for the configured #channel name, unless an ID was given. */
async function resolveChannel(web: WebClient, channel: string): Promise<string> {
	if (/^C[A-Z0-9]+$/.test(channel)) return channel;
	const name = channel.replace(/^#/, "");
	for await (const page of web.paginate("conversations.list", {
		types: "public_channel",
		exclude_archived: true,
		limit: 200,
	})) {
		for (const ch of (page as { channels?: { id: string; name: string }[] }).channels ?? []) {
			if (ch.name === name) return ch.id;
		}
	}
	throw new Error(`Channel #${name} not found (is percy a member? conversations.list needs channels:read)`);
}

async function main(): Promise<void> {
	const botToken = process.env.SLACK_BOT_TOKEN;
	const appToken = process.env.SLACK_APP_TOKEN;
	if (!botToken || !appToken) throw new Error("SLACK_BOT_TOKEN and SLACK_APP_TOKEN are required");

	const cfg = loadConfig();
	const percy = await Percy.create(cfg);
	const web = new WebClient(botToken);
	const channelId = await resolveChannel(web, cfg.channel);
	log(`percy up: channel ${channelId}, model ${percy.modelDescription()}, state ${cfg.stateDir}`);

	const socket = new SocketModeClient({ appToken });
	// Serialise per thread: prompts to a session that is already streaming are
	// rejected by the SDK, and Slack can deliver messages mid-run.
	const queues = new Map<string, Promise<unknown>>();
	const enqueue = (threadTs: string, job: () => Promise<void>): void => {
		const prev = queues.get(threadTs) ?? Promise.resolve();
		const next = prev.then(job);
		queues.set(threadTs, next.catch(() => undefined));
	};

	// The reply streaming in each thread, so Slack's stop button can find it
	const active = new Map<string, SlackReply>();
	const feedbackFile = path.join(cfg.stateDir, "feedback.jsonl");

	const ackQuietly = async (ack: () => Promise<void>) => {
		try {
			await ack();
		} catch {
			/* ack can fail on shutdown; Slack redelivers */
		}
	};

	socket.on("message", ({ body, ack }) => {
		void (async () => {
			await ackQuietly(ack);
			const event = body.event as MessageEvent | undefined;
			if (!event || event.channel !== channelId) return;
			// Only plain human messages: skip bots (percy's own replies), edits,
			// joins, file-only posts, etc. Add subtypes deliberately later.
			if (event.subtype || event.bot_id || !event.user) return;
			const text = (event.text ?? "").trim();
			if (!text) return;
			const threadTs = event.thread_ts ?? event.ts;
			if (!threadTs) return;
			const userId = event.user;
			const teamId = event.user_team ?? event.team ?? (body.team_id as string | undefined) ?? "";

			log(`message from ${userId} in thread ${threadTs}`);

			enqueue(threadTs, async () => {
				const reply = new SlackReply(
					web,
					{ channel: channelId, threadTs, userId, teamId, title: text },
					() => void percy.abort(threadTs),
				);
				active.set(threadTs, reply);
				const started = Date.now();
				try {
					await reply.begin();
					// Label the speaker so multi-person threads are readable to percy
					const labeled = await labelMessage(web, userId, text, event.ts);
					const answer = (await percy.prompt(threadTs, labeled, presentEvents(reply))).trim();
					if (!reply.stopped && !reply.hasText) {
						// A failed model call resolves with an empty message, not a throw
						reply.text(
							answer || ":warning: percy got no reply from the model. Try again, or start a new thread.",
						);
					}
				} catch (err) {
					log("run failed:", err instanceof Error ? err.message : err);
					reply.text("\n\n:warning: percy hit an error, try again or start a new thread.");
				} finally {
					await reply.finish().catch((err) => log("reply failed:", err instanceof Error ? err.message : err));
					active.delete(threadTs);
					log(`replied in thread ${threadTs} after ${((Date.now() - started) / 1000).toFixed(1)}s`);
				}
			});
		})();
	});

	// Slack's stop button on a processing agent session
	socket.on("agent_session_stopped", ({ body, ack }) => {
		void (async () => {
			await ackQuietly(ack);
			const event = body.event as { channel?: string; thread_ts?: string } | undefined;
			if (!event?.thread_ts || event.channel !== channelId) return;
			log(`stop requested in thread ${event.thread_ts}`);
			const reply = active.get(event.thread_ts);
			if (reply) reply.stopped = true;
			await percy.abort(event.thread_ts);
		})();
	});

	// Feedback buttons on finished replies: kept in feedback.jsonl for review
	socket.on("interactive", ({ body, ack }) => {
		void (async () => {
			await ackQuietly(ack);
			const payload = body as {
				type?: string;
				user?: { id?: string };
				container?: { channel_id?: string; message_ts?: string; thread_ts?: string };
				message?: { ts?: string; thread_ts?: string };
				actions?: { action_id?: string; value?: string }[];
			};
			if (payload.type !== "block_actions") return;
			const action = payload.actions?.find((a) => a.action_id === FEEDBACK_ACTION_ID);
			if (!action) return;
			const record = {
				time: new Date().toISOString(),
				value: action.value,
				user: payload.user?.id,
				channel: payload.container?.channel_id,
				threadTs: payload.message?.thread_ts ?? payload.container?.thread_ts,
				messageTs: payload.message?.ts ?? payload.container?.message_ts,
			};
			log(`feedback ${record.value} from ${record.user} in thread ${record.threadTs}`);
			await appendFile(feedbackFile, `${JSON.stringify(record)}\n`).catch(() => undefined);
		})();
	});

	const sweep = setInterval(() => void percy.sweep(SESSION_TTL_MS), SWEEP_INTERVAL_MS);
	const shutdown = (signal: string) => {
		log(`percy shutting down (${signal})`);
		clearInterval(sweep);
		void socket.disconnect().then(() => percy.dispose()).then(() => process.exit(0));
	};
	process.on("SIGTERM", () => shutdown("SIGTERM"));
	process.on("SIGINT", () => shutdown("SIGINT"));

	await socket.start();
}

// Run only as the entry point, so tests can import the helpers
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
	main().catch((err) => {
		console.error(err);
		process.exit(1);
	});
}
