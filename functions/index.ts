const DESTINATION_EMAIL = "taulbeepainting2@gmail.com";
const MAX_BODY_BYTES = 14_000_000;
const ALLOWED_ORIGINS = new Set([
  "https://taulbeepainting.app",
  "https://www.taulbeepainting.app",
  "https://taulbeepainting-app.rork.app",
]);

const isAllowedOrigin = (origin: string | null): boolean => Boolean(origin && (ALLOWED_ORIGINS.has(origin) || origin.endsWith(".rork.live") || origin.endsWith(".rorkdev.link")));

const corsHeaders = (origin: string | null): HeadersInit => ({
  "Access-Control-Allow-Origin": isAllowedOrigin(origin) ? origin as string : "https://taulbeepainting-app.rork.app",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Max-Age": "86400",
  Vary: "Origin",
});

const json = (body: unknown, status: number, origin: string | null): Response => Response.json(body, {
  status,
  headers: corsHeaders(origin),
});

const recentSubmissions = new Map<string, number>();
const isRateLimited = (request: Request): boolean => {
  const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";
  const now = Date.now();
  const previous = recentSubmissions.get(ip) ?? 0;
  if (now - previous < 60_000) return true;
  recentSubmissions.set(ip, now);
  if (recentSubmissions.size > 500) {
    for (const [key, timestamp] of recentSubmissions) if (now - timestamp > 60_000) recentSubmissions.delete(key);
  }
  return false;
};

export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin");

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }

    if (url.pathname === "/ping") {
      return json({ ok: true, now: new Date().toISOString() }, 200, origin);
    }

    if (url.pathname !== "/estimate" || request.method !== "POST") {
      return json({ ok: false, error: "Not found" }, 404, origin);
    }

    if (origin && !isAllowedOrigin(origin)) {
      return json({ ok: false, error: "Origin not allowed" }, 403, origin);
    }

    const contentLength = Number(request.headers.get("Content-Length") ?? "0");
    if (contentLength > MAX_BODY_BYTES) {
      return json({ ok: false, error: "Photos are too large. Remove one and try again." }, 413, origin);
    }

    try {
      const form = await request.formData();
      const name = String(form.get("name") ?? "").trim();
      const contact = String(form.get("contact") ?? "").trim();
      const startedAt = Number(form.get("startedAt") ?? "0");
      const honeypot = String(form.get("website") ?? "").trim();

      if (honeypot || !startedAt || Date.now() - startedAt < 2500) {
        return json({ ok: false, error: "Please review the form and try again." }, 400, origin);
      }
      if (name.length < 2 || contact.length < 5) {
        return json({ ok: false, error: "Name and contact information are required." }, 400, origin);
      }
      if (isRateLimited(request)) {
        return json({ ok: false, error: "Please wait a minute before sending another request." }, 429, origin);
      }

      form.delete("website");
      form.delete("startedAt");
      form.set("_subject", `New Taulbee Painting estimate request — ${name}`);
      form.set("_template", "table");
      form.set("_captcha", "false");
      form.set("source", "Taulbee Painting web app");

      const upstream = await fetch(`https://formsubmit.co/ajax/${DESTINATION_EMAIL}`, {
        method: "POST",
        headers: { Accept: "application/json" },
        body: form,
      });
      const payload = await upstream.json().catch((): null => null) as { success?: boolean | string; message?: string } | null;
      const succeeded = upstream.ok && (payload?.success === true || payload?.success === "true");
      if (!succeeded) {
        return json({ ok: false, error: "Direct delivery is unavailable. Use the email option instead." }, 502, origin);
      }

      return json({ ok: true }, 200, origin);
    } catch {
      return json({ ok: false, error: "We couldn't deliver that request. Use the email option instead." }, 500, origin);
    }
  },
};
