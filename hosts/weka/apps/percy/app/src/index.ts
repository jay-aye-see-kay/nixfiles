// Percy: a read-only pi agent living in Slack's #percy channel, one context
// window per thread. Slack Socket Mode only (outbound WebSocket), so nothing
// on weka is exposed. Runs as a systemd service with its own state dir.
import { loadConfig, Percy } from "./agent.js";
import { SocketModeClient } from "@slack/socket-mode";
import { WebClient } from "@slack/web-api";
import { pathToFileURL } from "node:url";

const SLACK_MESSAGE_CHUNK = 3900; // Slack rejects posts around 4k characters
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

/** Label a message so percy can tell speakers apart: [Name] text, @Name mentions. */
export async function labelMessage(web: WebClient, userId: string, text: string): Promise<string> {
	const mention = /<@([A-Z0-9]+)>/g;
	const needs = [userId, ...Array.from(text.matchAll(mention), (m) => m[1]!)];
	await Promise.all(needs.map((id) => userName(web, id)));
	const labeled = text.replace(mention, (_all, id: string) => `@${userNames.get(id) ?? id}`);
	return `[${userNames.get(userId) ?? userId}] ${labeled}`;
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

/** Split a reply into Slack-sized chunks, preferring newline boundaries. */
function chunk(text: string): string[] {
	if (text.length <= SLACK_MESSAGE_CHUNK) return [text];
	const parts: string[] = [];
	let rest = text;
	while (rest.length > SLACK_MESSAGE_CHUNK) {
		const window = rest.slice(0, SLACK_MESSAGE_CHUNK);
		const cut = Math.max(window.lastIndexOf("\n\n"), window.lastIndexOf("\n"), window.lastIndexOf(" "));
		const at = cut > SLACK_MESSAGE_CHUNK / 2 ? cut : SLACK_MESSAGE_CHUNK;
		parts.push(rest.slice(0, at));
		rest = rest.slice(at).replace(/^\n+/, "");
	}
	if (rest.trim()) parts.push(rest);
	return parts;
}

/**
 * Coalesce rapid stage changes into rare chat.update calls (Slack's
 * chat.update is tier-2, ~1/sec). The first set in a burst schedules one
 * update; later sets only change the text that update will carry.
 */
export class StagePoster {
	private pending?: NodeJS.Timeout;
	private text = "thinking…";
	constructor(
		private readonly update: (text: string) => Promise<unknown>,
		private readonly minIntervalMs = 1200,
	) {}
	set(text: string): void {
		if (text === this.text) return;
		this.text = text;
		if (!this.pending) {
			this.pending = setTimeout(() => {
				this.pending = undefined;
				void this.update(`_${this.text}_`);
			}, this.minIntervalMs);
		}
	}
	/** Drop a pending update so a stale stage can never overwrite the final reply. */
	finish(): void {
		if (this.pending) {
				clearTimeout(this.pending);
				this.pending = undefined;
		}
	}
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

	socket.on("message", ({ body, ack }) => {
		void (async () => {
			try {
				await ack();
			} catch {
				/* ack can fail on shutdown; the message stays queued client-side */
			}
			const event = body.event as MessageEvent | undefined;
			if (!event || event.channel !== channelId) return;
			// Only plain human messages: skip bots (percy's own replies), edits,
			// joins, file-only posts, etc. Add subtypes deliberately later.
			if (event.subtype || event.bot_id || !event.user) return;
			const text = (event.text ?? "").trim();
			if (!text) return;
			const threadTs = event.thread_ts ?? event.ts;
			if (!threadTs) return;

			log(`message from ${event.user} in thread ${threadTs}`);

			enqueue(threadTs, async () => {
				// A placeholder message carries progress: posted immediately, edited
				// as stages change, and replaced by the reply at the end.
				let placeholderTs: string | undefined;
				try {
					placeholderTs = (
						await web.chat.postMessage({ channel: channelId, thread_ts: threadTs, text: "_thinking…_" })
					).ts;
				} catch {
					/* no placeholder: fall back to posting the reply directly */
				}
				const stages = new StagePoster((text) =>
					web.chat.update({ channel: channelId, ts: placeholderTs!, text }).then(() => undefined),
				);
				// Final text: edit the placeholder in place, post fresh if it is gone
				const post = async (text: string) => {
					stages.finish();
					if (placeholderTs) {
						try {
							await web.chat.update({ channel: channelId, ts: placeholderTs, text });
							return;
						} catch {
							/* fall through to a fresh message */
						}
					}
					await web.chat.postMessage({ channel: channelId, thread_ts: threadTs, text });
				};
				try {
					// Label the speaker so multi-person threads are readable to percy
					const labeled = await labelMessage(web, event.user!, text);
					const reply = (await percy.prompt(threadTs, labeled, (stage) => stages.set(stage))).trim();
					if (!reply) {
						// A failed model call resolves with an empty message, not a throw
						await post(":warning: percy got no reply from the model. Try again, or start a new thread.");
						return;
					}
					const parts = chunk(reply);
					await post(parts[0]!);
					// Long replies continue as fresh messages: a single message cannot
					// grow past the chunk limit
					for (const part of parts.slice(1)) {
						await web.chat.postMessage({ channel: channelId, thread_ts: threadTs, text: part });
					}
				} catch (err) {
					log("run failed:", err instanceof Error ? err.message : err);
					await post(":warning: percy hit an error, try again or start a new thread.").catch(() => undefined);
				}
			});
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
