// Percy's read-only tools for the weka host, registered as an inline extension.
// Everything lives in the "percy" namespace with codemode exposure: the model
// reaches these through codemode scripts (tools.<name>(...)), never by calling
// them directly, so scripts can filter and aggregate before output reaches
// the model. Future tools (prometheus, alerts, docs) join the same namespace.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// journalctl unit patterns: name, glob, or instance. Passed as one argv, so
// there is no injection risk; the whitelist just keeps -u meaning a unit.
const UNIT = /^[A-Za-z0-9@:_.\\*,-]+$/;
const TIME = /^[\w: .+\-/]+$/;

const PRIORITIES = ["emerg", "alert", "crit", "err", "warning", "notice", "info", "debug"] as const;

const JournalParams = Type.Object({
	unit: Type.Optional(
		Type.String({ description: "systemd unit to filter by, e.g. mealie.service, nginx, or a glob like *.service" }),
	),
	since: Type.Optional(
		Type.String({ description: "Show entries logged since this time, journalctl format: '1 hour ago', '2026-01-01 12:00', '-2h'" }),
	),
	until: Type.Optional(Type.String({ description: "Show entries logged before this time, same format as since" })),
	priority: Type.Optional(
		Type.Union(PRIORITIES.map((p) => Type.Literal(p)), {
			description: "Only entries at this priority or worse, e.g. 'err' for errors",
		}),
	),
	grep: Type.Optional(Type.String({ description: "Only entries whose message matches this (case-insensitive)" })),
	lines: Type.Optional(
		Type.Number({ description: "How many entries to show, counting back from the newest (default 200, max 2000)" }),
	),
});

const JournalOutput = Type.Object({
	entries: Type.Array(
		Type.Object({
			time: Type.String(),
			unit: Type.String(),
			priority: Type.String(),
			message: Type.String(),
		}),
	),
	truncated: Type.Boolean(),
});

function priorityName(p: unknown): string {
	const num = Number(p);
	return PRIORITIES[num] ?? `p${String(p)}`;
}

export default function percyTools(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "journal",
		label: "Journal",
		description: "Read systemd journal (log) entries from this host, newest last. Filter by unit, time, priority, or message.",
		// One-line mention in the system prompt's tool list so the model knows
		// the host's logs are reachable, even though it can only call it from codemode.
		promptSnippet: "read systemd journal entries for this host (codemode)",
		promptGuidelines: ["Check the journal with the journal tool instead of guessing about service behaviour."],
		namespace: {
			name: "percy",
			description: "Read-only tools for inspecting the weka host",
			instructions:
				"Percy's tools for the host it runs on. They are codemode-exposed: call them from codemode scripts " +
				"(tools.<name>(args)), filter and aggregate there, and return only the relevant lines. " +
				"journal returns { entries: [{ time, unit, priority, message }], truncated }; " +
				"use describeTool('journal') for its parameters.",
		},
		exposure: "codemode",
		annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false },
		parameters: JournalParams,
		outputSchema: JournalOutput,
		execute: async (_toolCallId, params, signal) => {
			const lines = Math.min(Math.max(Math.floor(params.lines ?? 200), 1), 2000);
			const args = [
				"--no-pager",
				"--output=json",
				"--output-fields=__REALTIME_TIMESTAMP,SYSTEMD_UNIT,SYSLOG_IDENTIFIER,PRIORITY,MESSAGE",
				"--lines",
				String(lines),
			];

			for (const [flag, value, pattern] of [
				["--unit", params.unit, UNIT],
				["--since", params.since, TIME],
				["--until", params.until, TIME],
				["--grep", params.grep, TIME],
			] as const) {
				if (value === undefined) continue;
				if (!pattern.test(value) || value.length > 100) {
					return {
						isError: true,
						details: {},
						content: [{ type: "text" as const, text: `Invalid value for ${flag}: ${value}` }],
					};
				}
				args.push(flag, value);
			}
			if (params.priority !== undefined) args.push("--priority", params.priority);

			const result = await pi.exec("journalctl", args, { signal, timeout: 30_000, maxBuffer: 8 * 1024 * 1024 });

			// journalctl exits 1 when nothing matches, which is an empty result, not an error
			const entries = result.stdout
				.split("\n")
				.map((line) => line.trim())
				.filter(Boolean)
				.map((line) => {
					let e: Record<string, unknown>;
					try {
						e = JSON.parse(line) as Record<string, unknown>;
					} catch {
						return null;
					}
					const message = Array.isArray(e.MESSAGE) ? e.MESSAGE.join("\n") : String(e.MESSAGE ?? "");
					const time = new Date(Number(e.__REALTIME_TIMESTAMP) / 1000).toISOString();
					const unit = String(e.SYSTEMD_UNIT ?? e.SYSLOG_IDENTIFIER ?? "-");
					return { time, unit, priority: priorityName(e.PRIORITY), message };
				})
				.filter((e): e is { time: string; unit: string; priority: string; message: string } => e !== null);

			if (entries.length === 0 && result.code !== 0 && !result.truncated) {
				return {
					isError: true,
					details: {},
					content: [{ type: "text" as const, text: `journalctl exited ${result.code}: ${result.stderr.trim() || "no entries"}` }],
				};
			}

			const structuredContent = {
				entries,
				truncated: result.truncated || entries.length >= lines,
			};
			// Text view for direct callers: first 50 lines, since the full set
			// normally flows through codemode's structuredContent instead.
			const preview = entries
				.slice(0, 50)
				.map((e) => `${e.time} ${e.unit} [${e.priority}] ${e.message}`)
				.join("\n");
			const text = `${preview}${entries.length > 50 ? `\n… ${entries.length} entries total (truncated view)` : ""}`;

			return {
				content: [{ type: "text" as const, text }],
				structuredContent,
				details: {},
			};
		},
	});
}
