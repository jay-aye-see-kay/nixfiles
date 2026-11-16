// Percy's read-only tools for the weka host, registered as an inline extension.
// Everything lives in the "percy" namespace with codemode exposure: the model
// reaches these through codemode scripts (tools.<name>(...)), never by calling
// them directly, so scripts can filter and aggregate before output reaches
// the model. Future tools (prometheus, alerts, docs) join the same namespace.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// journalctl/systemctl get each value as its own argv entry, so there is no
// injection risk; these whitelists just keep -u meaning a unit and stop a
// value from being read as a flag.
const UNIT = /^[A-Za-z0-9@:_.\\*,-]+$/;
const TIME = /^[\w: .+\-/]+$/;
const NOT_A_FLAG = /^[^-\n][^\n]*$/;

const PRIORITIES = ["emerg", "alert", "crit", "err", "warning", "notice", "info", "debug"] as const;
// Long messages (stack traces, JSON blobs) are clipped so one entry cannot
// flood the context; scripts can narrow with grep/since to see more.
const MAX_MESSAGE_CHARS = 800;

const JournalParams = Type.Object({
	unit: Type.Optional(
		Type.String({
			description:
				"systemd unit, e.g. podman-homeassistant.service or nginx. Globs (podman-*) only match units systemd knows; use tools.units() to find names",
		}),
	),
	since: Type.Optional(
		Type.String({
			description:
				"Entries since this local time: 'today', 'yesterday', '-2h', '-30min', '12:00' (today), '2026-11-15 12:00'. Not 'today 12:00'",
		}),
	),
	until: Type.Optional(Type.String({ description: "Entries before this time, same format as since" })),
	priority: Type.Optional(
		Type.Union(PRIORITIES.map((p) => Type.Literal(p)), {
			description: "Only entries at this priority or worse. Containers log all stderr as err, so this is unreliable for podman-* units",
		}),
	),
	grep: Type.Optional(
		Type.String({ description: "PCRE regex the message must match (case-insensitive), e.g. 'error|fail' or 'ERROR \\(MainThread\\)'" }),
	),
	lines: Type.Optional(
		Type.Number({ description: "Max entries, the newest ones within the filters (default 200, max 2000)" }),
	),
});

const JournalEntry = Type.Object({
	time: Type.String({ description: "Local time, YYYY-MM-DD HH:MM:SS" }),
	unit: Type.String(),
	priority: Type.String(),
	message: Type.String(),
});
const JournalOutput = Type.Object({
	entries: Type.Array(JournalEntry),
	truncated: Type.Boolean({ description: "More entries matched than were returned: narrow since/grep/unit" }),
	hint: Type.Optional(Type.String()),
});

const UnitsParams = Type.Object({
	pattern: Type.Optional(Type.String({ description: "Unit glob, e.g. '*home*' or 'podman-*'. Default: all services and timers" })),
	state: Type.Optional(
		Type.Union([Type.Literal("failed"), Type.Literal("active"), Type.Literal("inactive")], {
			description: "Only units in this active state",
		}),
	),
});
const UnitsOutput = Type.Object({
	units: Type.Array(
		Type.Object({ unit: Type.String(), active: Type.String(), sub: Type.String(), description: Type.String() }),
	),
});

const StatusParams = Type.Object({ unit: Type.String({ description: "Exact unit name, e.g. podman-homeassistant.service" }) });
const STATUS_PROPERTIES = [
	"ActiveState",
	"SubState",
	"Result",
	"ActiveEnterTimestamp",
	"InactiveEnterTimestamp",
	"NRestarts",
	"ExecMainStatus",
	"MemoryCurrent",
	"CPUUsageNSec",
	"Description",
];

type Json = null | boolean | number | string | Json[] | { [key: string]: Json };
type ToolResult = {
	content: { type: "text"; text: string }[];
	structuredContent?: { [key: string]: Json };
	details: Record<string, never>;
	isError?: boolean;
};

const fail = (text: string): ToolResult => ({ isError: true, details: {}, content: [{ type: "text", text }] });

function priorityName(p: unknown): string {
	return PRIORITIES[Number(p)] ?? `p${String(p)}`;
}

/**
 * journalctl --output=json emits MESSAGE as a byte array when it is not
 * valid UTF-8 or contains control characters (container output with ANSI
 * colours). Decode it to text and strip the colour codes, which would
 * otherwise cost the model several tokens per byte.
 */
// biome-ignore lint/suspicious/noControlCharactersInRegex: matching ANSI escapes
const ANSI = /\x1b\[[0-9;?]*[A-Za-z]/g;
export function decodeMessage(raw: unknown): string {
	let text: string;
	if (Array.isArray(raw) && raw.every((b) => typeof b === "number")) text = Buffer.from(raw as number[]).toString("utf8");
	else if (Array.isArray(raw)) text = raw.map(decodeMessage).join("\n");
	else text = String(raw ?? "");
	text = text.replace(ANSI, "").trimEnd();
	return text.length > MAX_MESSAGE_CHARS ? `${text.slice(0, MAX_MESSAGE_CHARS)}… [${text.length} chars]` : text;
}

/** Local wall-clock time without the zone (the prompt states the zone once). */
export function localTime(micros: unknown): string {
	const d = new Date(Number(micros) / 1000);
	const pad = (n: number) => String(n).padStart(2, "0");
	return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

export default function percyTools(pi: ExtensionAPI): void {
	const namespace = {
		name: "percy",
		description: "Read-only tools for inspecting the weka host",
		instructions:
			"Percy's tools for the host it runs on. Call them from codemode scripts (await tools.<name>(args)), " +
			"filter and aggregate there, and return only the relevant lines. " +
			"units({pattern?, state?}) lists systemd services/timers; status({unit}) gives one unit's state, uptime and restarts; " +
			"journal({unit?, since?, until?, priority?, grep?, lines?}) returns { entries: [{ time, unit, priority, message }], truncated }. " +
			"Containers run as podman-<name>.service. Times are local. Find the unit with units() before filtering the journal by it.",
	};
	const annotations = { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false };

	pi.registerTool({
		name: "journal",
		label: "Journal",
		description: "Read systemd journal (log) entries from this host, oldest first. Filter by unit, time, priority, or message regex.",
		promptSnippet: "read systemd journal entries for this host (codemode)",
		promptGuidelines: ["Check the journal with the journal tool instead of guessing about service behaviour."],
		namespace,
		exposure: "codemode",
		annotations,
		parameters: JournalParams,
		outputSchema: JournalOutput,
		execute: async (_toolCallId, params, signal): Promise<ToolResult> => {
			const lines = Math.min(Math.max(Math.floor(params.lines ?? 200), 1), 2000);
			const args = [
				"--no-pager",
				"--output=json",
				// _SYSTEMD_UNIT is the trusted (underscore) field; plain SYSTEMD_UNIT does not exist
				"--output-fields=__REALTIME_TIMESTAMP,_SYSTEMD_UNIT,SYSLOG_IDENTIFIER,PRIORITY,MESSAGE",
				"--lines",
				String(lines),
			];

			for (const [flag, value, pattern, max] of [
				["--unit", params.unit, UNIT, 100],
				["--since", params.since, TIME, 100],
				["--until", params.until, TIME, 100],
				["--grep", params.grep, NOT_A_FLAG, 300],
			] as const) {
				if (value === undefined || value === "") continue;
				if (!pattern.test(value) || value.length > max) return fail(`Invalid value for ${flag}: ${value}`);
				args.push(flag, value);
			}
			if (params.priority !== undefined) args.push("--priority", params.priority);

			const result = await pi.exec("journalctl", args, { signal, timeout: 30_000, maxBuffer: 16 * 1024 * 1024 });
			// A misspelt unit (homeassistant for podman-homeassistant.service) just matches nothing
			const empty = (): ToolResult => {
				const hint = params.unit
					? `No entries for unit '${params.unit}' in this range. If unsure of the name, check tools.units({ pattern: '*name*' }).`
					: "No entries in this range.";
				return { content: [{ type: "text", text: hint }], structuredContent: { entries: [], truncated: false, hint }, details: {} };
			};

			const entries = result.stdout
				.split("\n")
				.filter((line) => line.trim())
				.flatMap((line) => {
					try {
						const e = JSON.parse(line) as Record<string, unknown>;
						return [
							{
								ts: Number(e.__REALTIME_TIMESTAMP),
								time: localTime(e.__REALTIME_TIMESTAMP),
								unit: String(e._SYSTEMD_UNIT ?? e.SYSLOG_IDENTIFIER ?? "-"),
								priority: priorityName(e.PRIORITY),
								message: decodeMessage(e.MESSAGE),
							},
						];
					} catch {
						return [];
					}
				})
				// --grep with --lines can come back newest-first; always return oldest first
				.sort((a, b) => a.ts - b.ts)
				.map(({ ts: _ts, ...e }) => e);

			if (entries.length === 0 && result.code !== 0) {
				const stderr = result.stderr.trim();
				// journalctl exits 1 with no output when nothing matches: an empty result, not an error
				if (!stderr) return empty();
				if (/Failed to add filter for units/.test(stderr)) {
					return fail(`No unit matches '${params.unit}'. Use tools.units({ pattern: '*name*' }) to find the unit name.`);
				}
				if (/Failed to parse timestamp/.test(stderr)) {
					return fail(`${stderr}. Use 'today', '-2h', '12:00' or 'YYYY-MM-DD HH:MM'.`);
				}
				return fail(`journalctl exited ${result.code}: ${stderr}`);
			}

			if (entries.length === 0) return empty();
			const structuredContent = { entries, truncated: result.truncated || entries.length >= lines };
			// Text view for direct callers: last 50 entries, since the full set
			// normally flows through codemode's structuredContent instead.
			const shown = entries.slice(-50);
			const text =
				(entries.length > shown.length ? `… ${entries.length - shown.length} earlier entries not shown\n` : "") +
				shown.map((e) => `${e.time} ${e.unit} [${e.priority}] ${e.message}`).join("\n");
			return { content: [{ type: "text", text: text || "no entries" }], structuredContent, details: {} };
		},
	});

	pi.registerTool({
		name: "units",
		label: "Units",
		description: "List systemd services and timers on this host with their state. Use it to find exact unit names.",
		promptSnippet: "list systemd services and their state (codemode)",
		namespace,
		exposure: "codemode",
		annotations,
		parameters: UnitsParams,
		outputSchema: UnitsOutput,
		execute: async (_toolCallId, params, signal): Promise<ToolResult> => {
			const args = ["list-units", "--all", "--output=json", "--no-pager", "--type=service,timer"];
			if (params.state) args.push(`--state=${params.state}`);
			if (params.pattern) {
				if (!UNIT.test(params.pattern) || params.pattern.length > 100) return fail(`Invalid pattern: ${params.pattern}`);
				args.push("--", params.pattern);
			}
			const result = await pi.exec("systemctl", args, { signal, timeout: 15_000 });
			if (result.code !== 0) return fail(`systemctl exited ${result.code}: ${result.stderr.trim()}`);
			let raw: { unit: string; load: string; active: string; sub: string; description: string }[];
			try {
				raw = JSON.parse(result.stdout || "[]");
			} catch {
				return fail("could not parse systemctl output");
			}
			// Units referenced but not installed (load=not-found) are noise
			const units = raw
				.filter((u) => u.load !== "not-found")
				.map(({ unit, active, sub, description }) => ({ unit, active, sub, description: description === unit ? "" : description }));
			return {
				content: [{ type: "text", text: units.map((u) => `${u.unit} ${u.active}/${u.sub} ${u.description}`).join("\n") || "no units" }],
				structuredContent: { units },
				details: {},
			};
		},
	});

	pi.registerTool({
		name: "status",
		label: "Status",
		description: "One systemd unit's state, when it last started/stopped, restart count, exit status, memory and CPU use.",
		promptSnippet: "a systemd unit's state, uptime and restarts (codemode)",
		namespace,
		exposure: "codemode",
		annotations,
		parameters: StatusParams,
		outputSchema: Type.Record(Type.String(), Type.String()),
		execute: async (_toolCallId, params, signal): Promise<ToolResult> => {
			if (!UNIT.test(params.unit) || params.unit.length > 100) return fail(`Invalid unit: ${params.unit}`);
			const result = await pi.exec("systemctl", ["show", `--property=${STATUS_PROPERTIES.join(",")}`, "--", params.unit], {
				signal,
				timeout: 15_000,
			});
			if (result.code !== 0) return fail(`systemctl exited ${result.code}: ${result.stderr.trim()}`);
			const props: Record<string, string> = {};
			for (const line of result.stdout.split("\n")) {
				const at = line.indexOf("=");
				if (at > 0) props[line.slice(0, at)] = line.slice(at + 1);
			}
			if (props.ActiveState === "inactive" && !props.Description) return fail(`Unit ${params.unit} not found`);
			const mem = Number(props.MemoryCurrent);
			if (Number.isFinite(mem)) props.MemoryCurrent = `${Math.round(mem / 1024 / 1024)} MiB`;
			const cpu = Number(props.CPUUsageNSec);
			if (Number.isFinite(cpu)) props.CPUUsageNSec = `${Math.round(cpu / 1e9)} s`;
			return {
				content: [{ type: "text", text: Object.entries(props).map(([k, v]) => `${k}=${v}`).join("\n") }],
				structuredContent: props,
				details: {},
			};
		},
	});
}
