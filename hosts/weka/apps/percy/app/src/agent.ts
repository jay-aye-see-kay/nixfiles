// Percy's agent core: one pi SDK session per Slack thread, persisted to disk
// so a thread keeps its context across restarts and idle eviction.
import {
	createAgentSession,
	createCodemodeExtension,
	DefaultResourceLoader,
	ModelRuntime,
	SessionManager,
	SettingsManager,
	type AgentSession,
	type AgentSessionEvent,
} from "@earendil-works/pi-coding-agent";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import percyTools from "./tools.js";

export interface PercyConfig {
	stateDir: string;
	channel: string;
	model: { provider: string; id: string };
	cwd: string;
	thinkingLevel: ThinkingLevel;
}

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";

export function loadConfig(env: NodeJS.ProcessEnv = process.env): PercyConfig {
	return {
		stateDir: env.PERCY_STATE_DIR ?? "/var/lib/percy",
		channel: env.PERCY_CHANNEL ?? "ask-percy",
		model: { provider: env.PERCY_MODEL_PROVIDER ?? "opencode-go", id: env.PERCY_MODEL ?? "glm-5.3-flash" },
		// Read-only view of the whole filesystem; tools decide what is reachable.
		cwd: env.PERCY_CWD ?? "/",
		// Lookups here are shallow; "high" mostly bought slower turns
		thinkingLevel: (env.PERCY_THINKING as ThinkingLevel | undefined) ?? "medium",
	};
}

const SYSTEM_PROMPT = `You are percy, a read-only assistant living on weka, a NixOS home server
(timezone Australia/Melbourne). You answer in a Slack thread in #percy.

Replies are rendered as Markdown in Slack:
- Lead with the answer. Keep it short and conversational; more detail only when asked.
- Use **bold**, _italic_, \`code\`, bullet lists and fenced code blocks. No headings or tables unless asked.
- Your tool calls already show in the thread as progress steps, so don't narrate them
  ("let me check…"); if you write between tool calls, keep it to one short line.

Looking things up:
- The percy tools are called from codemode scripts: \`await tools.units(...)\`,
  \`tools.status(...)\`, \`tools.journal(...)\`. Do as much as you can in one script:
  find the unit, read its logs, filter and count in JavaScript, and return only the
  lines that answer the question (aim for under ~100 lines).
- Containers run as podman-<name>.service (e.g. podman-homeassistant.service). If
  unsure of a unit name, call tools.units({ pattern: "*name*" }) first rather than guessing.
- Journal times are local. Each message tells you the current time; turn "this
  afternoon" or "today" into since/until values from it.
- Unit files (with the exact ExecStart and options) are readable under /etc/systemd/system.

Several people may talk in one thread. Every message starts with a header like
[Jack · Mon 16 Nov 14:05]: the sender's display name and the local time it was sent.
Mentions of others appear as @Name. Use these to tell who said what.

You are strictly read-only: you cannot edit files, restart services or run commands,
so never claim to have changed anything. For questions about a service's status or
recent behaviour, check status and the journal instead of guessing.`;

interface ThreadEntry {
	session: AgentSession;
	chain: Promise<unknown>;
	lastUsed: number;
}

export class Percy {
	private readonly threads = new Map<string, ThreadEntry>();
	// thread_ts (Slack) -> session file path, persisted so threads survive restarts
	private readonly index = new Map<string, string>();
	private readonly sessionsDir: string;
	private readonly indexFile: string;
	private modelRuntime: ModelRuntime | undefined;

	private constructor(private readonly cfg: PercyConfig) {
		this.sessionsDir = path.join(cfg.stateDir, "sessions");
		this.indexFile = path.join(cfg.stateDir, "threads.json");
	}

	static async create(cfg: PercyConfig): Promise<Percy> {
		const percy = new Percy(cfg);
		await mkdir(percy.sessionsDir, { recursive: true });
		try {
			const raw = JSON.parse(await readFile(percy.indexFile, "utf8")) as Record<string, string>;
			for (const [threadTs, sessionFile] of Object.entries(raw)) percy.index.set(threadTs, sessionFile);
		} catch {
			// No index yet, or unreadable: threads start fresh sessions.
		}
		// Percy's own state: cached model catalog and auth. The OpenCode Go key
		// arrives via OPENCODE_API_KEY in the environment.
		percy.modelRuntime = await ModelRuntime.create({
			authPath: path.join(cfg.stateDir, "auth.json"),
			modelsPath: path.join(cfg.stateDir, "models-store.json"),
		});
		return percy;
	}

	modelDescription(): string {
		return `${this.cfg.model.provider}/${this.cfg.model.id}`;
	}

	private async newSession(threadTs: string): Promise<AgentSession> {
		const recorded = this.index.get(threadTs);
		const sessionManager = recorded
			? SessionManager.open(recorded)
			: SessionManager.create(this.cfg.cwd, this.sessionsDir);

		const resourceLoader = new DefaultResourceLoader({
			cwd: this.cfg.cwd,
			agentDir: this.cfg.stateDir,
			extensionFactories: [createCodemodeExtension({ mode: "on" }), percyTools],
			systemPromptOverride: () => SYSTEM_PROMPT,
			appendSystemPromptOverride: () => [],
		});
		await resourceLoader.reload();

		const model = this.modelRuntime?.getModel(this.cfg.model.provider, this.cfg.model.id);
		if (!model) throw new Error(`Model ${this.modelDescription()} not found in the catalog`);
		if (!this.modelRuntime?.hasConfiguredAuth(this.cfg.model.provider)) {
			throw new Error(`No auth configured for ${this.cfg.model.provider} (set OPENCODE_API_KEY)`);
		}

		const { session } = await createAgentSession({
			cwd: this.cfg.cwd,
			model,
			modelRuntime: this.modelRuntime,
			sessionManager,
			resourceLoader,
			// In-memory settings (nothing to persist for a service). defaultTools
			// replaces the active set without unregistering anything, unlike the
			// factory's tools allowlist, which drops non-matching extension tools:
			// read-only built-ins, plus codemode to reach the percy namespace.
			settingsManager: SettingsManager.inMemory({
				defaultTools: ["read", "grep", "find", "ls", "codemode"],
				defaultThinkingLevel: this.cfg.thinkingLevel,
			}),
		});

		if (!recorded) {
			const sessionFile = session.sessionFile;
			if (sessionFile) {
				this.index.set(threadTs, sessionFile);
				await this.saveIndex();
			}
		}
		return session;
	}

	private async saveIndex(): Promise<void> {
		const entries = Object.fromEntries(this.index);
		await writeFile(this.indexFile, JSON.stringify(entries, null, "\t") + "\n");
	}

	/**
	 * Prompt the thread's session. Prompts to the same thread are serialized,
	 * because the SDK rejects prompt() while a session is already streaming.
	 * onEvent sees the run's events (text deltas, tool calls) as they happen.
	 * Resolves with the reply text; rejects if the run fails.
	 */
	async prompt(threadTs: string, text: string, onEvent?: (event: AgentSessionEvent) => void): Promise<string> {
		let entry = this.threads.get(threadTs);
		if (!entry) {
			entry = { session: await this.newSession(threadTs), chain: Promise.resolve(), lastUsed: Date.now() };
			this.threads.set(threadTs, entry);
		}
		entry.lastUsed = Date.now();
		const run = entry.chain
			.then(() => {
				if (!onEvent) return entry!.session.prompt(text);
				// Subscribe just before the run so events map to this prompt
				const unsubscribe = entry!.session.subscribe(onEvent);
				return entry!.session.prompt(text).finally(unsubscribe);
			})
			.then(() => entry!.session.getLastAssistantText() ?? "");
		entry.chain = run.catch(() => undefined); // a failed run must not poison the chain
		return run;
	}

	/** Stop the thread's in-flight run, if any (Slack's stop button). */
	async abort(threadTs: string): Promise<void> {
		await this.threads.get(threadTs)?.session.abort();
	}

	/** Dispose sessions idle longer than ttlMs; their context stays on disk. */
	async sweep(ttlMs: number): Promise<void> {
		const now = Date.now();
		for (const [threadTs, entry] of this.threads) {
			if (now - entry.lastUsed < ttlMs) continue;
			// Skip threads with a run in flight (chain unresolved).
			const settled = await Promise.race([entry.chain.then(() => true), new Promise((r) => setTimeout(() => r(false), 0))]);
			if (!settled) continue;
			this.threads.delete(threadTs);
			entry.session.dispose();
		}
	}

	async dispose(): Promise<void> {
		for (const entry of this.threads.values()) entry.session.dispose();
		this.threads.clear();
	}
}
