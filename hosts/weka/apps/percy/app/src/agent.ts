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
} from "@earendil-works/pi-coding-agent";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import percyTools from "./tools.js";

export interface PercyConfig {
	stateDir: string;
	channel: string;
	model: { provider: string; id: string };
	cwd: string;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): PercyConfig {
	return {
		stateDir: env.PERCY_STATE_DIR ?? "/var/lib/percy",
		channel: env.PERCY_CHANNEL ?? "ask-percy",
		model: { provider: env.PERCY_MODEL_PROVIDER ?? "opencode-go", id: env.PERCY_MODEL ?? "glm-5.3-flash" },
		// Read-only view of the whole filesystem; tools decide what is reachable.
		cwd: env.PERCY_CWD ?? "/",
	};
}

const SYSTEM_PROMPT = `You are percy, a read-only assistant living on weka, a NixOS home server.

Every reply you write is posted to Slack's #percy channel, so:
- Keep replies short and conversational; more detail only when asked.
- Use plain text with Slack-style formatting (*bold*, _italic_, \`code\`). No headings, no tables unless asked.

You can read the filesystem with the read, grep, find, and ls tools.
You inspect the host through the percy tool namespace (currently: journal, the
systemd log reader), which you reach from codemode scripts: tools.journal(...)
returns { entries, truncated } — filter and aggregate in the script and return
only the relevant lines. describeNamespace("percy") lists the namespace.

You are strictly read-only: you cannot edit files or run commands, so never
claim to have changed anything. For questions about a service's status or
recent behaviour, read the journal instead of guessing.`;

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
	 * Resolves with the reply text; rejects if the run fails.
	 */
	async prompt(threadTs: string, text: string): Promise<string> {
		let entry = this.threads.get(threadTs);
		if (!entry) {
			entry = { session: await this.newSession(threadTs), chain: Promise.resolve(), lastUsed: Date.now() };
			this.threads.set(threadTs, entry);
		}
		entry.lastUsed = Date.now();
		const run = entry.chain.then(() => entry!.session.prompt(text)).then(() => entry!.session.getLastAssistantText() ?? "");
		entry.chain = run.catch(() => undefined); // a failed run must not poison the chain
		return run;
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
