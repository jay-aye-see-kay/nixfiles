// Shared pieces of percy's tools: the "percy" codemode namespace every tool
// joins, the result type, and time parsing/formatting.

export type Json = null | boolean | number | string | Json[] | { [key: string]: Json };
export type ToolResult = {
	content: { type: "text"; text: string }[];
	structuredContent?: { [key: string]: Json };
	details: Record<string, never>;
	isError?: boolean;
};

export const fail = (text: string): ToolResult => ({ isError: true, details: {}, content: [{ type: "text", text }] });

export const namespace = {
	name: "percy",
	description: "Read-only tools for inspecting the weka host: logs, metrics, alerts and systemd",
	instructions:
		"Percy's tools for the host it runs on. Call them from codemode scripts (await tools.<name>(args)), " +
		"filter and aggregate there, and return only the relevant lines.\n" +
		"Logs (Loki, 90 days, every unit): logs({query, since?, until?, limit?}) takes LogQL, e.g. " +
		'{unit="podman-homeassistant.service", level=~"warning|error"} |= "zha". ' +
		"Log queries return { entries: [{ time, unit, level, message }], truncated }; metric queries " +
		"(count_over_time, rate...) return { series: [{ labels, points: [{ time, value }] }] }. " +
		"logLabels({label?}) lists label names, or one label's values (e.g. label 'unit').\n" +
		"Metrics (Prometheus, 2 years): query({query, time?}) is an instant PromQL query, " +
		"queryRange({query, since?, until?, step?}) a range one; both return { series: [{ labels, value | points }] }. " +
		"metrics({match?}) lists metric names (regex filter). alerts() returns firing/pending alerts and active silences. " +
		"targets() returns scrape targets and their health.\n" +
		"systemd: units({pattern?, state?}) lists services/timers; status({unit}) gives one unit's state, uptime and restarts; " +
		"journal({unit?, since?, until?, priority?, grep?, lines?}) reads journald directly, a fallback for when Loki is down.\n" +
		"Containers run as podman-<name>.service. Times are local (Australia/Melbourne).",
};

export const annotations = { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false };

/** Local wall-clock time without the zone (the prompt states the zone once). */
export function localTime(input: Date | number): string {
	const d = input instanceof Date ? input : new Date(input);
	const pad = (n: number) => String(n).padStart(2, "0");
	return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

const UNITS_MS: Record<string, number> = { s: 1e3, m: 60e3, min: 60e3, h: 3600e3, d: 86400e3, w: 7 * 86400e3 };

/**
 * Parse a time the way the journal tool's since/until do, into a Date:
 * 'now', 'today', 'yesterday', relative '-2h'/'-30min'/'-7d', 'HH:MM' (today),
 * 'YYYY-MM-DD', 'YYYY-MM-DD HH:MM[:SS]' (local), or an ISO timestamp.
 * Returns undefined when it can't parse.
 */
export function parseTime(text: string, now = new Date()): Date | undefined {
	const t = text.trim().toLowerCase();
	if (t === "now") return now;
	if (t === "today" || t === "yesterday") {
		const d = new Date(now);
		d.setHours(0, 0, 0, 0);
		if (t === "yesterday") d.setDate(d.getDate() - 1);
		return d;
	}
	const rel = /^-\s*(\d+(?:\.\d+)?)\s*(s|m|min|h|d|w)$/.exec(t);
	if (rel) return new Date(now.getTime() - Number(rel[1]) * UNITS_MS[rel[2]!]!);
	const hm = /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/.exec(t);
	if (hm) {
		const d = new Date(now);
		d.setHours(Number(hm[1]), Number(hm[2]), Number(hm[3] ?? 0), 0);
		return d;
	}
	// Date-only and "YYYY-MM-DD HH:MM" are local; Date treats a bare date as UTC
	const local = /^(\d{4})-(\d{2})-(\d{2})(?:[ t](\d{1,2}):(\d{2})(?::(\d{2}))?)?$/.exec(t);
	if (local) {
		const [, y, mo, da, h, mi, s] = local;
		return new Date(Number(y), Number(mo) - 1, Number(da), Number(h ?? 0), Number(mi ?? 0), Number(s ?? 0));
	}
	const d = new Date(text);
	return Number.isNaN(d.getTime()) ? undefined : d;
}

/** fetch JSON from a local service, with a timeout and the tool call's abort signal. */
export async function getJson(url: URL, signal: AbortSignal | undefined, timeoutMs = 30_000): Promise<unknown> {
	const timeout = AbortSignal.timeout(timeoutMs);
	const res = await fetch(url, { signal: signal ? AbortSignal.any([signal, timeout]) : timeout });
	const body = await res.text();
	if (!res.ok) {
		// Prometheus and Loki explain bad queries in the body ({"error": ...} or plain text)
		let detail = body.trim();
		try {
			const parsed = JSON.parse(body) as { error?: string };
			if (parsed.error) detail = parsed.error;
		} catch {
			// plain text body
		}
		throw new Error(`${url.pathname} returned ${res.status}: ${detail.slice(0, 500)}`);
	}
	return JSON.parse(body);
}
