// Percy's monitoring tools: Prometheus (metrics, alerts, scrape targets),
// Alertmanager (silences) and Loki (logs), all on weka's localhost. Every call
// is a GET to a query endpoint, so these can only read. Codemode scripts have
// no network, so these tools are how scripts reach the monitoring stack.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { annotations, fail, getJson, type Json, localTime, namespace, parseTime, type ToolResult } from "./common.js";

const PROMETHEUS = process.env.PERCY_PROMETHEUS_URL ?? "http://127.0.0.1:9090";
const ALERTMANAGER = process.env.PERCY_ALERTMANAGER_URL ?? "http://127.0.0.1:9093";
const LOKI = process.env.PERCY_LOKI_URL ?? "http://127.0.0.1:3100";

// Long lines (stack traces, JSON blobs) are clipped so one entry cannot flood
// the context; scripts can narrow the query to see more.
const MAX_MESSAGE_CHARS = 800;
// Range results past this many points are cut off (and flagged truncated)
const MAX_POINTS = 20_000;
// Aim for about this many points per series when no step is given
const DEFAULT_POINTS = 120;

const TIME_HELP =
	"'now', 'today', 'yesterday', '-2h', '-30min', '-7d', '12:00' (today), '2026-11-15' or '2026-11-15 12:00' (local time)";

// biome-ignore lint/suspicious/noControlCharactersInRegex: matching ANSI escapes
const ANSI = /\x1b\[[0-9;?]*[A-Za-z]/g;
function clip(text: string): string {
	const clean = text.replace(ANSI, "").trimEnd();
	return clean.length > MAX_MESSAGE_CHARS ? `${clean.slice(0, MAX_MESSAGE_CHARS)}… [${clean.length} chars]` : clean;
}

/** Prometheus/Loki sample values are strings; NaN and ±Inf stay strings, since JSON has no number for them. */
function sampleValue(v: unknown): number | string {
	const n = Number(v);
	return Number.isFinite(n) ? n : String(v);
}

const ok = (text: string, structuredContent: { [key: string]: Json }): ToolResult => ({
	content: [{ type: "text", text: text || "no results" }],
	structuredContent,
	details: {},
});

/** Resolve since/until params to a [start, end] range, or an error message. */
function timeRange(since: string | undefined, until: string | undefined, defaultSince: string): [Date, Date] | string {
	const now = new Date();
	const start = parseTime(since || defaultSince, now);
	const end = until ? parseTime(until, now) : now;
	if (!start) return `Can't parse since '${since}'. Use ${TIME_HELP}.`;
	if (!end) return `Can't parse until '${until}'. Use ${TIME_HELP}.`;
	if (start >= end) return `since (${localTime(start)}) must be before until (${localTime(end)})`;
	return [start, end];
}

function url(base: string, path: string, params: Record<string, string | undefined>): URL {
	const u = new URL(path, base);
	for (const [k, v] of Object.entries(params)) if (v !== undefined) u.searchParams.set(k, v);
	return u;
}

type Labels = Record<string, string>;
const labelText = (labels: Labels) =>
	`{${Object.entries(labels)
		.map(([k, v]) => `${k}="${v}"`)
		.join(", ")}}`;

type Series = { labels: Labels; points: { time: string; value: number | string }[] };

/** Matrix results (Prometheus range queries, Loki metric queries) as series of local-time points. */
function matrix(result: { metric: Labels; values: [number, string][] }[]): { series: Series[]; truncated: boolean } {
	let budget = MAX_POINTS;
	const series: Series[] = [];
	for (const r of result) {
		if (budget <= 0) return { series, truncated: true };
		const values = r.values.slice(-budget);
		budget -= values.length;
		series.push({ labels: r.metric, points: values.map(([t, v]) => ({ time: localTime(t * 1000), value: sampleValue(v) })) });
	}
	return { series, truncated: false };
}

function seriesText(series: Series[]): string {
	return series
		.slice(0, 20)
		.map((s) => {
			const pts = s.points;
			const last = pts.at(-1);
			const nums = pts.map((p) => p.value).filter((v): v is number => typeof v === "number");
			const range = nums.length ? ` min=${Math.min(...nums)} max=${Math.max(...nums)}` : "";
			return `${labelText(s.labels)} ${pts.length} points${range} last=${last?.value} @ ${last?.time}`;
		})
		.join("\n")
		.concat(series.length > 20 ? `\n… ${series.length - 20} more series` : "");
}

const SeriesSchema = Type.Object({
	labels: Type.Record(Type.String(), Type.String()),
	points: Type.Array(Type.Object({ time: Type.String(), value: Type.Union([Type.Number(), Type.String()]) })),
});

export default function monitoringTools(pi: ExtensionAPI): void {
	const common = { namespace, exposure: "codemode" as const, annotations };

	pi.registerTool({
		...common,
		name: "query",
		label: "Prometheus query",
		description:
			"Instant PromQL query against weka's Prometheus (node_exporter, smartctl, ZFS, UPS, service exporters). Returns each series' current value.",
		promptSnippet: "instant PromQL query (codemode)",
		promptGuidelines: ["Check metrics with the query/queryRange tools instead of guessing about resource use or history."],
		parameters: Type.Object({
			query: Type.String({ description: "PromQL, e.g. 'node_filesystem_avail_bytes{mountpoint=\"/\"}' or 'up == 0'" }),
			time: Type.Optional(Type.String({ description: `Evaluate at this time instead of now: ${TIME_HELP}` })),
		}),
		outputSchema: Type.Object({
			resultType: Type.String(),
			series: Type.Array(Type.Object({ labels: Type.Record(Type.String(), Type.String()), value: Type.Union([Type.Number(), Type.String()]) })),
		}),
		execute: async (_id, params, signal): Promise<ToolResult> => {
			let time: string | undefined;
			if (params.time) {
				const t = parseTime(params.time);
				if (!t) return fail(`Can't parse time '${params.time}'. Use ${TIME_HELP}.`);
				time = String(t.getTime() / 1000);
			}
			try {
				const body = (await getJson(url(PROMETHEUS, "/api/v1/query", { query: params.query, time }), signal)) as {
					data: { resultType: string; result: unknown };
				};
				const { resultType, result } = body.data;
				let series: { labels: Labels; value: number | string }[];
				if (resultType === "vector") {
					series = (result as { metric: Labels; value: [number, string] }[]).map((r) => ({
						labels: r.metric,
						value: sampleValue(r.value[1]),
					}));
				} else if (resultType === "scalar" || resultType === "string") {
					series = [{ labels: {}, value: sampleValue((result as [number, string])[1]) }];
				} else {
					return fail(`Got a ${resultType} result; use queryRange for range vectors, or wrap in a function like max_over_time()`);
				}
				const text = series
					.slice(0, 100)
					.map((s) => `${labelText(s.labels)} ${s.value}`)
					.join("\n");
				return ok(text || "empty result (no series matched)", { resultType, series });
			} catch (err) {
				return fail(String(err instanceof Error ? err.message : err));
			}
		},
	});

	pi.registerTool({
		...common,
		name: "queryRange",
		label: "Prometheus range query",
		description: "PromQL range query against weka's Prometheus: each series' values over a time range (2 years kept).",
		promptSnippet: "PromQL over a time range (codemode)",
		parameters: Type.Object({
			query: Type.String({ description: "PromQL, e.g. 'rate(node_cpu_seconds_total{mode!=\"idle\"}[5m])'" }),
			since: Type.Optional(Type.String({ description: `Range start (default -1h): ${TIME_HELP}` })),
			until: Type.Optional(Type.String({ description: "Range end (default now), same format as since" })),
			step: Type.Optional(
				Type.String({ description: `Resolution, e.g. '30s', '5m', '1h'. Default: about ${DEFAULT_POINTS} points over the range` }),
			),
		}),
		outputSchema: Type.Object({ series: Type.Array(SeriesSchema), truncated: Type.Boolean(), step: Type.String() }),
		execute: async (_id, params, signal): Promise<ToolResult> => {
			const range = timeRange(params.since, params.until, "-1h");
			if (typeof range === "string") return fail(range);
			const [start, end] = range;
			const step = params.step || `${Math.max(15, Math.ceil((end.getTime() - start.getTime()) / 1000 / DEFAULT_POINTS))}s`;
			try {
				const body = (await getJson(
					url(PROMETHEUS, "/api/v1/query_range", {
						query: params.query,
						start: String(start.getTime() / 1000),
						end: String(end.getTime() / 1000),
						step,
					}),
					signal,
					60_000,
				)) as { data: { result: { metric: Labels; values: [number, string][] }[] } };
				const { series, truncated } = matrix(body.data.result);
				return ok(seriesText(series) || "empty result (no series matched)", { series, truncated, step });
			} catch (err) {
				return fail(String(err instanceof Error ? err.message : err));
			}
		},
	});

	pi.registerTool({
		...common,
		name: "metrics",
		label: "Metrics",
		description: "List the metric names Prometheus has, with their type and help text. Use it to find what to query.",
		promptSnippet: "list Prometheus metric names (codemode)",
		parameters: Type.Object({
			match: Type.Optional(Type.String({ description: "Case-insensitive regex on the name or help text, e.g. 'zfs|pool' or 'temp'" })),
		}),
		outputSchema: Type.Object({
			metrics: Type.Array(Type.Object({ name: Type.String(), type: Type.String(), help: Type.String() })),
		}),
		execute: async (_id, params, signal): Promise<ToolResult> => {
			let re: RegExp | undefined;
			try {
				if (params.match) re = new RegExp(params.match, "i");
			} catch {
				return fail(`Invalid regex: ${params.match}`);
			}
			try {
				const [names, meta] = (await Promise.all([
					getJson(url(PROMETHEUS, "/api/v1/label/__name__/values", {}), signal),
					getJson(url(PROMETHEUS, "/api/v1/metadata", {}), signal),
				])) as [{ data: string[] }, { data: Record<string, { type: string; help: string }[]> }];
				const metrics = names.data
					.map((name) => ({ name, type: meta.data[name]?.[0]?.type ?? "", help: meta.data[name]?.[0]?.help ?? "" }))
					.filter((m) => !re || re.test(m.name) || re.test(m.help));
				return ok(metrics.map((m) => `${m.name} (${m.type}) ${m.help}`).join("\n"), { metrics });
			} catch (err) {
				return fail(String(err instanceof Error ? err.message : err));
			}
		},
	});

	pi.registerTool({
		...common,
		name: "alerts",
		label: "Alerts",
		description:
			"Alerts that are firing or pending in Prometheus, every alert rule with its state and health, and active Alertmanager silences.",
		promptSnippet: "firing alerts, alert rules and silences (codemode)",
		parameters: Type.Object({}),
		outputSchema: Type.Object({
			alerts: Type.Array(
				Type.Object({
					name: Type.String(),
					state: Type.String(),
					since: Type.String(),
					labels: Type.Record(Type.String(), Type.String()),
					summary: Type.String(),
					value: Type.String(),
				}),
			),
			rules: Type.Array(
				Type.Object({ group: Type.String(), name: Type.String(), state: Type.String(), health: Type.String(), lastError: Type.String() }),
			),
			silences: Type.Array(
				Type.Object({ matchers: Type.String(), comment: Type.String(), createdBy: Type.String(), endsAt: Type.String() }),
			),
			silencesError: Type.Optional(Type.String()),
		}),
		execute: async (_id, _params, signal): Promise<ToolResult> => {
			type PromAlert = { labels: Labels; annotations: Labels; state: string; activeAt: string; value: string };
			type Rule = { name: string; type: string; state?: string; health: string; lastError?: string };
			type Silence = {
				status: { state: string };
				matchers: { name: string; value: string; isRegex: boolean; isEqual?: boolean }[];
				comment: string;
				createdBy: string;
				endsAt: string;
			};
			try {
				const [alertsBody, rulesBody] = (await Promise.all([
					getJson(url(PROMETHEUS, "/api/v1/alerts", {}), signal),
					getJson(url(PROMETHEUS, "/api/v1/rules", { type: "alert" }), signal),
				])) as [{ data: { alerts: PromAlert[] } }, { data: { groups: { name: string; rules: Rule[] }[] } }];
				const alerts = alertsBody.data.alerts.map((a) => ({
					name: a.labels.alertname ?? "",
					state: a.state,
					since: localTime(new Date(a.activeAt)),
					labels: a.labels,
					summary: a.annotations.summary ?? a.annotations.description ?? "",
					value: a.value,
				}));
				const rules = rulesBody.data.groups.flatMap((g) =>
					g.rules.map((r) => ({ group: g.name, name: r.name, state: r.state ?? "", health: r.health, lastError: r.lastError ?? "" })),
				);
				// Alertmanager being down shouldn't hide the alerts themselves
				let silences: { matchers: string; comment: string; createdBy: string; endsAt: string }[] = [];
				let silencesError: string | undefined;
				try {
					const raw = (await getJson(url(ALERTMANAGER, "/api/v2/silences", {}), signal)) as Silence[];
					silences = raw
						.filter((s) => s.status.state === "active")
						.map((s) => ({
							matchers: s.matchers
								.map((m) => `${m.name}${m.isEqual === false ? "!" : ""}${m.isRegex ? "=~" : "="}"${m.value}"`)
								.join(", "),
							comment: s.comment,
							createdBy: s.createdBy,
							endsAt: localTime(new Date(s.endsAt)),
						}));
				} catch (err) {
					silencesError = String(err instanceof Error ? err.message : err);
				}
				const text = [
					alerts.length
						? alerts.map((a) => `${a.state.toUpperCase()} ${a.name} since ${a.since}: ${a.summary}`).join("\n")
						: "No alerts firing or pending.",
					`${rules.length} alert rules${rules.some((r) => r.health !== "ok") ? `, unhealthy: ${rules.filter((r) => r.health !== "ok").map((r) => r.name).join(", ")}` : ", all healthy"}.`,
					silences.length ? `Silences: ${silences.map((s) => `${s.matchers} until ${s.endsAt}`).join("; ")}` : "No active silences.",
					silencesError ? `(Alertmanager unreachable: ${silencesError})` : "",
				]
					.filter(Boolean)
					.join("\n");
				return ok(text, { alerts, rules, silences, ...(silencesError ? { silencesError } : {}) });
			} catch (err) {
				return fail(String(err instanceof Error ? err.message : err));
			}
		},
	});

	pi.registerTool({
		...common,
		name: "targets",
		label: "Scrape targets",
		description: "Prometheus scrape targets (exporters and services) with their health, last scrape and last error.",
		promptSnippet: "Prometheus scrape targets and their health (codemode)",
		parameters: Type.Object({}),
		outputSchema: Type.Object({
			targets: Type.Array(
				Type.Object({ job: Type.String(), instance: Type.String(), health: Type.String(), lastScrape: Type.String(), lastError: Type.String() }),
			),
		}),
		execute: async (_id, _params, signal): Promise<ToolResult> => {
			try {
				const body = (await getJson(url(PROMETHEUS, "/api/v1/targets", { state: "active" }), signal)) as {
					data: { activeTargets: { labels: Labels; health: string; lastScrape: string; lastError: string }[] };
				};
				const targets = body.data.activeTargets.map((t) => ({
					job: t.labels.job ?? "",
					instance: t.labels.instance ?? "",
					health: t.health,
					lastScrape: localTime(new Date(t.lastScrape)),
					lastError: t.lastError,
				}));
				return ok(targets.map((t) => `${t.job} ${t.instance} ${t.health}${t.lastError ? ` (${t.lastError})` : ""}`).join("\n"), {
					targets,
				});
			} catch (err) {
				return fail(String(err instanceof Error ? err.message : err));
			}
		},
	});

	pi.registerTool({
		...common,
		name: "logs",
		label: "Logs",
		description:
			"Query weka's logs in Loki with LogQL: every systemd unit's journal, 90 days. Log queries return entries; metric queries (count_over_time, rate) return series.",
		promptSnippet: "query logs with LogQL (codemode)",
		promptGuidelines: ["Check logs with the logs tool instead of guessing about service behaviour."],
		parameters: Type.Object({
			query: Type.String({
				description:
					'LogQL. Labels: unit (e.g. podman-homeassistant.service), level (debug/info/notice/warning/error/crit), identifier. E.g. \'{unit="loki.service"} |= "error"\', \'{level=~"error|crit"}\', \'sum by (unit) (count_over_time({level="error"}[1h]))\'',
			}),
			since: Type.Optional(Type.String({ description: `Range start (default -1h): ${TIME_HELP}` })),
			until: Type.Optional(Type.String({ description: "Range end (default now), same format as since" })),
			limit: Type.Optional(Type.Number({ description: "Max log entries, the newest within the range (default 200, max 2000)" })),
		}),
		outputSchema: Type.Object({
			entries: Type.Optional(
				Type.Array(Type.Object({ time: Type.String(), unit: Type.String(), level: Type.String(), message: Type.String() })),
			),
			series: Type.Optional(Type.Array(SeriesSchema)),
			truncated: Type.Boolean({ description: "More matched than was returned: narrow the range or the query" }),
		}),
		execute: async (_id, params, signal): Promise<ToolResult> => {
			const range = timeRange(params.since, params.until, "-1h");
			if (typeof range === "string") return fail(range);
			const [start, end] = range;
			const limit = Math.min(Math.max(Math.floor(params.limit ?? 200), 1), 2000);
			const ns = (d: Date) => `${BigInt(d.getTime()) * 1_000_000n}`;
			try {
				const body = (await getJson(
					url(LOKI, "/loki/api/v1/query_range", {
						query: params.query,
						start: ns(start),
						end: ns(end),
						limit: String(limit),
						// Newest entries first, so the limit keeps the most recent ones
						direction: "backward",
					}),
					signal,
					60_000,
				)) as { data: { resultType: string; result: unknown[] } };

				if (body.data.resultType === "matrix") {
					const { series, truncated } = matrix(body.data.result as { metric: Labels; values: [number, string][] }[]);
					return ok(seriesText(series) || "no matching logs in this range", { series, truncated });
				}

				const streams = body.data.result as { stream: Labels; values: [string, string][] }[];
				const entries = streams
					.flatMap((s) =>
						s.values.map(([t, line]) => ({
							ns: BigInt(t),
							unit: s.stream.unit ?? s.stream.identifier ?? "-",
							level: s.stream.level ?? "",
							message: clip(line),
						})),
					)
					.sort((a, b) => (a.ns < b.ns ? -1 : a.ns > b.ns ? 1 : 0))
					.slice(-limit)
					.map(({ ns: t, ...e }) => ({ time: localTime(Number(t / 1_000_000n)), ...e }));
				const truncated = entries.length >= limit;
				if (entries.length === 0) {
					const hint = "No matching logs in this range. Check label values with tools.logLabels({ label: 'unit' }).";
					return ok(hint, { entries: [], truncated: false });
				}
				const shown = entries.slice(-50);
				const text =
					(entries.length > shown.length ? `… ${entries.length - shown.length} earlier entries not shown\n` : "") +
					shown.map((e) => `${e.time} ${e.unit} [${e.level}] ${e.message}`).join("\n");
				return ok(text, { entries, truncated });
			} catch (err) {
				return fail(String(err instanceof Error ? err.message : err));
			}
		},
	});

	pi.registerTool({
		...common,
		name: "logLabels",
		label: "Log labels",
		description: "Loki label names, or the values one label takes (e.g. every unit that has logged), over a time range.",
		promptSnippet: "list Loki log labels or a label's values (codemode)",
		parameters: Type.Object({
			label: Type.Optional(Type.String({ description: "A label name such as 'unit' or 'level'; omit to list label names" })),
			since: Type.Optional(Type.String({ description: `Range start (default -7d): ${TIME_HELP}` })),
		}),
		outputSchema: Type.Object({ values: Type.Array(Type.String()) }),
		execute: async (_id, params, signal): Promise<ToolResult> => {
			if (params.label && !/^[A-Za-z_][A-Za-z0-9_]*$/.test(params.label)) return fail(`Invalid label name: ${params.label}`);
			const range = timeRange(params.since, undefined, "-7d");
			if (typeof range === "string") return fail(range);
			const [start, end] = range;
			const path = params.label ? `/loki/api/v1/label/${params.label}/values` : "/loki/api/v1/labels";
			try {
				const body = (await getJson(
					url(LOKI, path, { start: `${BigInt(start.getTime()) * 1_000_000n}`, end: `${BigInt(end.getTime()) * 1_000_000n}` }),
					signal,
				)) as { data?: string[] };
				const values = body.data ?? [];
				return ok(values.join("\n"), { values });
			} catch (err) {
				return fail(String(err instanceof Error ? err.message : err));
			}
		},
	});
}
