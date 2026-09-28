// Renders every story in a running Storybook and reports the ones that break.
//
//   yarn storybook                       # in another terminal (Node 22: nvm use)
//   yarn storybook:smoke                 # every story
//   yarn storybook:smoke profilemodal    # story ids containing any given word
//   yarn storybook:smoke --dark          # render in the dark theme
//   yarn storybook:smoke --mobile        # render at phone width (390px)
//   yarn storybook:smoke --shots=/tmp/x  # save a screenshot per story
//
// A story fails when it does not finish rendering, its play function throws,
// the page throws, or the console logs an error. GraphQL errors from the mock
// engine (a mock of the wrong shape) are reported as warnings: the story
// usually still renders, just with a hole where the bad field was.
//
// A story that fails is retried once; if it then passes it is listed as FLKY
// (usually an animated element checked for visibility on a busy machine).
//
// With --mobile, play functions are reported, not failed: they are written
// against the desktop layout, and some of what they click or look for (nav
// links, hover buttons) is hidden at phone width. Rendering errors still fail.
//
// Storybook's own test runner needs vitest 3+, and this repo is on 0.34, so
// this drives Storybook's preview iframe directly with Playwright.
import { mkdirSync } from "node:fs";
import { chromium } from "playwright";

const args = process.argv.slice(2);
const flag = (name) => args.find((a) => a === `--${name}` || a.startsWith(`--${name}=`));
const flagValue = (name) => flag(name)?.split("=").slice(1).join("=") || undefined;
const base = flagValue("url") ?? "http://localhost:6006";
const theme = flag("dark") ? "dark" : "light";
const mobile = Boolean(flag("mobile"));
const viewport = mobile ? { width: 390, height: 844 } : { width: 1200, height: 900 };
const shots = flagValue("shots");
const filters = args.filter((a) => !a.startsWith("--")).map((a) => a.toLowerCase());

let index;
try {
  index = await (await fetch(`${base}/index.json`)).json();
} catch {
  console.error(`No Storybook at ${base}. Start it with: nvm use && yarn storybook`);
  process.exit(2);
}
const ids = Object.values(index.entries)
  .filter((e) => e.type === "story")
  .map((e) => e.id)
  .filter((id) => filters.length === 0 || filters.some((f) => id.includes(f)));
if (shots) mkdirSync(shots, { recursive: true });

let browser;
try {
  browser = await chromium.launch({ channel: "chrome" });
} catch {
  browser = await chromium.launch();
}

async function check(id) {
  const page = await browser.newPage({ viewport });
  const errors = [];
  const consoleErrors = [];
  const warnings = [];
  page.on("pageerror", (e) => errors.push(e.message.split("\n")[0]));
  page.on("console", (m) => {
    const text = m.text();
    if (m.type() === "error" && !/Failed to load resource/.test(text)) consoleErrors.push(text.split("\n")[0]);
    if (m.type() === "warning" && /^\[story:/.test(text)) warnings.push(text.split("\n")[0]);
  });
  await page.addInitScript(() => {
    window.__smoke = [];
    const hook = () => {
      const channel = window.__STORYBOOK_ADDONS_CHANNEL__;
      if (!channel) return setTimeout(hook, 20);
      for (const event of ["storyFinished", "storyErrored", "storyThrewException", "playFunctionThrewException", "storyMissing"]) {
        channel.on(event, (payload) => window.__smoke.push({ event, status: payload?.status, message: payload?.message ?? payload?.description }));
      }
    };
    hook();
  });
  const url = `${base}/iframe.html?id=${id}&viewMode=story&globals=theme:${theme}`;
  await page.goto(url, { waitUntil: "load" });
  await page
    .waitForFunction(() => window.__smoke.some((e) => e.event !== "storyRendered"), null, { timeout: 30000 })
    .catch(() => errors.push("timed out waiting for the story to finish"));
  await page.waitForTimeout(300);
  const events = await page.evaluate(() => window.__smoke);
  const notes = [];
  const playFailed = events.some((e) => e.event === "playFunctionThrewException");
  // At phone width a failed play function is a note; its assertion also
  // reaches the console and marks the story finished with an error status.
  const playIsNote = mobile && playFailed;
  for (const e of events) {
    const line = `${e.event}: ${String(e.message ?? "").split("\n")[0]}`;
    if (e.event === "playFunctionThrewException" && playIsNote) notes.push(line);
    else if (e.event !== "storyFinished") errors.push(line);
    else if (e.status && e.status !== "success" && !playIsNote) errors.push(`story finished with status ${e.status}`);
  }
  if (!playIsNote) errors.push(...consoleErrors);
  if (shots) await page.screenshot({ path: `${shots}/${id}.png`, fullPage: true });
  await page.close();
  return { id, errors: [...new Set(errors)], warnings: [...new Set(warnings)], notes };
}

const results = [];
for (const id of ids) results.push(await check(id));
// A story that fails once and then passes is reported as flaky rather than
// failed: visibility checks on animated elements can time out when the
// machine is busy. It still shows in the output so it can be hardened.
for (const [i, r] of results.entries()) {
  if (!r.errors.length) continue;
  const retry = await check(r.id);
  if (!retry.errors.length) results[i] = { ...retry, flaky: r.errors };
}
await browser.close();

const failed = results.filter((r) => r.errors.length);
const warned = results.filter((r) => !r.errors.length && r.warnings.length);
const noted = results.filter((r) => !r.errors.length && r.notes.length);
const flaky = results.filter((r) => r.flaky);
for (const r of results) {
  const mark = r.errors.length ? "FAIL" : r.flaky ? "FLKY" : r.warnings.length ? "WARN" : r.notes.length ? "PLAY" : "ok  ";
  console.log(`${mark} ${r.id}`);
  for (const e of r.errors.slice(0, 3)) console.log(`       ${e.slice(0, 240)}`);
  for (const w of r.warnings.slice(0, 2)) console.log(`       ${w.slice(0, 240)}`);
  for (const n of r.notes.slice(0, 1)) console.log(`       ${n.slice(0, 240)}`);
  for (const f of (r.flaky ?? []).slice(0, 1)) console.log(`       failed once, passed on retry: ${f.slice(0, 200)}`);
}
const playNote = noted.length ? `, ${noted.length} play functions that assume the desktop layout` : "";
const flakyNote = flaky.length ? `, ${flaky.length} passed only on retry` : "";
console.log(`\n${results.length} stories: ${results.length - failed.length} passed, ${failed.length} failed, ${warned.length} with mock warnings${playNote}${flakyNote}.`);
process.exit(failed.length ? 1 : 0);
