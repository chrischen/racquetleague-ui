// Dev-only scenario injection. Mounted by server.js ahead of Vite's middleware
// so it sees POST /graphql from both the browser and SSR (server.js points SSR
// at this server in dev). See dev/scenarios/README.md.
//
// With no scenario selected the request goes to next() untouched and Vite's
// proxy streams it to the backend as before. The ordering matters: the proxy
// pipes the raw request into its upstream request, so if anything here read
// the body before calling next(), the proxied request would hang forever.
import express from "express";
import { Readable } from "node:stream";
import { executeWithMocks, operationNameOf } from "./engine.mjs";
import { createSchemaLoader } from "./mock-schema.mjs";
import { createRegistry } from "./registry.mjs";

export const COOKIE = "pkuru_scenario";
export const HEADER = "x-pkuru-scenario";

function readCookie(header, name) {
  for (const part of (header ?? "").split(";")) {
    const i = part.indexOf("=");
    if (i > 0 && part.slice(0, i).trim() === name) return decodeURIComponent(part.slice(i + 1).trim());
  }
  return undefined;
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  return Buffer.concat(chunks);
}

// res.end rather than res.json: SSR forwards the browser's request headers,
// and Express would answer a matching If-None-Match with an empty 304.
function sendJson(res, status, body, scenarioName) {
  res.statusCode = status;
  res.setHeader("content-type", "application/json; charset=utf-8");
  res.setHeader("cache-control", "no-store");
  if (scenarioName) res.setHeader(HEADER, scenarioName);
  res.end(JSON.stringify(body));
}

const VIEWER_ID_TTL_MS = 60_000;

const viewerIdIn = (data) => data?.viewer?.user?.id ?? data?.viewer?.profile?.id ?? undefined;

function operationTypeOf(request) {
  const match = /^\s*(query|mutation|subscription)\b/.exec(request.query ?? "");
  return match ? match[1] : "query";
}

const safeRedirect = (to) => (typeof to === "string" && to.startsWith("/") && !to.startsWith("//") ? to : "/");

const escapeHtml = (s) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);

export function createScenarioMiddleware({ scenariosDir, schemaPath, upstream }) {
  const registry = createRegistry(scenariosDir);
  const getSchema = createSchemaLoader(schemaPath);

  // Overlay patches get the signed-in user's id so they can change that user
  // wherever it appears. The app stores one record per id: a copy left
  // unpatched under another path (viewer.user, an RSVP list, a mutation
  // payload) overwrites the patched one. The id comes from the response when
  // it selects the viewer, otherwise from one small lookup per session.
  const viewerIds = new Map();
  async function viewerIdFor(req, data) {
    const cookie = req.headers.cookie ?? "";
    const fromData = viewerIdIn(data);
    if (fromData) {
      viewerIds.set(cookie, { id: fromData, at: Date.now() });
      return fromData;
    }
    const cached = viewerIds.get(cookie);
    if (cached && Date.now() - cached.at < VIEWER_ID_TTL_MS) return cached.id;
    let id = null;
    try {
      const r = await fetch(upstream, {
        method: "POST",
        headers: { "content-type": "application/json", cookie },
        body: JSON.stringify({ query: "query ScenarioViewerId { viewer { user { id } } }" }),
      });
      id = viewerIdIn((await r.json())?.data) ?? null;
    } catch (e) {
      console.warn("[scenario] could not look up the signed-in user:", e.message);
    }
    viewerIds.set(cookie, { id, at: Date.now() });
    return id;
  }

  async function overlay(scenario, req, res, raw, request) {
    const upstreamRes = await fetch(upstream, {
      method: "POST",
      headers: {
        "content-type": req.headers["content-type"] ?? "application/json",
        accept: req.headers.accept ?? "*/*",
        cookie: req.headers.cookie ?? "",
      },
      body: raw,
    });
    for (const cookie of upstreamRes.headers.getSetCookie?.() ?? []) res.append("Set-Cookie", cookie);

    const contentType = upstreamRes.headers.get("content-type") ?? "";
    if (!contentType.includes("json")) {
      // Multipart (@defer) or an error page: pass it through unpatched. fetch
      // has already decoded any content-encoding, so that header is dropped.
      res.statusCode = upstreamRes.status;
      res.setHeader("content-type", contentType);
      res.setHeader(HEADER, scenario.name);
      if (upstreamRes.body) Readable.fromWeb(upstreamRes.body).pipe(res);
      else res.end();
      return;
    }
    const json = await upstreamRes.json();
    if (scenario.patch && json.data) {
      const context = {
        operation: operationTypeOf(request),
        viewerId: await viewerIdFor(req, json.data),
      };
      json.data = scenario.patch(operationNameOf(request), json.data, request.variables ?? {}, context) ?? json.data;
    }
    sendJson(res, upstreamRes.status, json, scenario.name);
  }

  async function graphql(req, res, next) {
    if (req.method !== "POST" || req.path !== "/graphql") return next();
    const name = req.get(HEADER) || readCookie(req.headers.cookie, COOKIE);
    // Must stay ahead of readBody; see the note at the top of the file.
    if (!name) return next();

    try {
      const scenario = await registry.load(name);
      if (!scenario) {
        console.warn(`[scenario] unknown scenario "${name}"; clear it at /__dev/scenario/off`);
        return sendJson(res, 400, { errors: [{ message: `Unknown dev scenario "${name}". See /__dev/scenario.` }] });
      }
      const raw = await readBody(req);
      const request = JSON.parse(raw.toString("utf8"));

      if (scenario.mode === "overlay") return await overlay(scenario, req, res, raw, request);

      const result = await executeWithMocks(getSchema(), scenario.mocks, request, { label: `scenario:${name}` });
      if (scenario.patch && result.data) {
        const context = { operation: operationTypeOf(request), viewerId: viewerIdIn(result.data) };
        result.data = scenario.patch(operationNameOf(request), result.data, request.variables ?? {}, context) ?? result.data;
      }
      sendJson(res, 200, result, name);
    } catch (e) {
      console.error(`[scenario] ${name}:`, e);
      if (!res.headersSent) sendJson(res, 500, { errors: [{ message: `Dev scenario "${name}" failed: ${e.message}` }] }, name);
    }
  }

  const routes = express.Router();

  routes.get("/__dev/scenario", async (req, res, next) => {
    try {
      const active = readCookie(req.headers.cookie, COOKIE);
      const scenarios = await registry.list();
      const rows = scenarios
        .map(
          (s) => `<tr${s.name === active ? ' class="active"' : ""}>
  <td><a href="/__dev/scenario/${encodeURIComponent(s.name)}?to=/">${escapeHtml(s.name)}</a></td>
  <td>${escapeHtml(s.mode)}</td>
  <td>${escapeHtml(s.description)}</td>
</tr>`,
        )
        .join("\n");
      res.setHeader("cache-control", "no-store");
      res.type("html").send(`<!doctype html>
<title>Dev scenarios</title>
<style>
  body { font: 14px/1.5 system-ui, sans-serif; margin: 2rem auto; max-width: 56rem; padding: 0 1rem; color: #111; }
  table { border-collapse: collapse; width: 100%; }
  td, th { text-align: left; padding: .5rem .75rem; border-bottom: 1px solid #e5e7eb; vertical-align: top; }
  tr.active { background: #fef2f2; }
  code { background: #f3f4f6; padding: 0 .25rem; border-radius: 4px; }
</style>
<h1>Dev scenarios</h1>
<p>Active: <strong>${active ? escapeHtml(active) : "none (real backend)"}</strong>${active ? ' · <a href="/__dev/scenario/off?to=/">turn off</a>' : ""}</p>
<p>A scenario answers <code>/graphql</code> for this browser only (cookie <code>${COOKIE}</code>). Add <code>?to=/some/path</code> to a link to land somewhere else. Scenario files live in <code>dev/scenarios/</code>.</p>
<table>
<tr><th>Scenario</th><th>Mode</th><th>Description</th></tr>
${rows}
</table>`);
    } catch (e) {
      next(e);
    }
  });

  routes.get("/__dev/scenario/off", (req, res) => {
    res.setHeader("Set-Cookie", `${COOKIE}=; Path=/; Max-Age=0; SameSite=Lax`);
    res.redirect(302, safeRedirect(req.query.to));
  });

  routes.get("/__dev/scenario/:name", async (req, res, next) => {
    try {
      const scenario = await registry.load(req.params.name);
      if (!scenario) return res.status(404).type("text").send(`No scenario "${req.params.name}" in dev/scenarios/.`);
      // Not HttpOnly: the badge server.js injects reads it from document.cookie.
      res.setHeader("Set-Cookie", `${COOKIE}=${encodeURIComponent(scenario.name)}; Path=/; SameSite=Lax`);
      res.redirect(302, safeRedirect(req.query.to));
    } catch (e) {
      next(e);
    }
  });

  return { graphql, routes };
}
