// Percy: a read-only pi agent living in Slack's #percy channel, one context
// window per thread. Slack Socket Mode only (outbound WebSocket), so nothing
// on weka is exposed. Runs as a systemd service with its own state dir.
import { loadConfig, Percy } from "./agent.js";
import { SocketModeClient } from "@slack/socket-mode";
import { WebClient } from "@slack/web-api";

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

			// Acknowledge while working, so the thread knows percy saw it.
			void web.reactions.add({ channel: channelId, timestamp: event.ts!, name: "eyes" }).catch(() => undefined);
			log(`message from ${event.user} in thread ${threadTs}`);

			enqueue(threadTs, async () => {
				try {
					const reply = (await percy.prompt(threadTs, text)).trim();
					if (!reply) {
						// A failed model call resolves with an empty message, not a throw
						await web.chat.postMessage({
							channel: channelId,
							thread_ts: threadTs,
							text: ":warning: percy got no reply from the model. Try again, or start a new thread.",
						});
						return;
					}
					for (const part of chunk(reply)) {
						await web.chat.postMessage({ channel: channelId, thread_ts: threadTs, text: part });
					}
				} catch (err) {
					log("run failed:", err instanceof Error ? err.message : err);
					await web.chat
						.postMessage({
							channel: channelId,
							thread_ts: threadTs,
							text: ":warning: percy hit an error, try again or start a new thread.",
						})
						.catch(() => undefined);
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

main().catch((err) => {
	console.error(err);
	process.exit(1);
});
