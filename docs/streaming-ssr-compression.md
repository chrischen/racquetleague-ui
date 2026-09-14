# Streaming SSR with gzip, immutable assets, and an early shell

Status: shipped in racquetleague-ui, 2026-09-07. Written as a porting guide for
any project built on the same frontend bootstrap (Express `server.js`, React 18
`renderToPipeableStream`, `PreloadInsertingStreamNode`, `RelaySSRUtils`,
react-router data routes, Vite client/server builds).

Verified against: react 18.3.1, react-dom 18.3.1, react-router-dom 6.22.3,
express 4.18.2, compression 1.7.4, express-static-gzip 2.1.7, isbot 3.7.1,
rescript-relay 3.0.0-rc.4, Node 20.

## What it achieves

Measured on the live events page, logged out, from a browser user agent:

| | Before | After |
|---|---|---|
| HTML on the wire | 645 KB, uncompressed | 55 KB, gzip |
| First render (shell readable) | ~570 ms, nothing until the whole page was ready | ~50 ms |
| Page complete | ~570 ms plus transfer | ~250 ms |
| Hashed asset revalidation on a repeat visit | all ~100 files, every navigation | none for a year |

Four changes, in three files. Their order matters when porting: change 2 must
land with change 1, or change 1 hangs every page.

## How the pieces fit

Streaming and compression only coexist if the compressor flushes at the moments
React wants bytes to leave. A compressor buffers until it has a full block, so a
small shell sits in zlib until the first Suspense boundary resolves, and the
"streaming" silently degrades to one burst at the end. Nothing errors.

The bootstrap already has most of the chain; it was only missing its last link:

1. React's Node renderer calls `destination.flush()` after each write **when the
   destination has such a method** (react-dom-server.node, 18.3.1).
2. The render is piped into `PreloadInsertingStreamNode`, whose `flush()`
   forwards to `this._writable.flush()` **if it exists**.
3. The `compression` middleware is what installs `res.flush()`. Until it is
   mounted, step 2 forwards into nothing.

So mounting `compression()` completes the chain rather than fighting it. Two
things about the stream class had to change to make that safe, covered below.

Measured with a synthetic 1.5 s boundary, shell readable at: no compression
12 ms; `compression()` in front of a plain transform 1514 ms (broken); with the
flush chain intact 2 ms.

## Change 1: compress the SSR response (`server.js`)

```js
import compression from "compression";
// …
const app = express();

if (!process.env.PKURU_NO_COMPRESSION) app.use(compression());
```

Mount it before every route. It can sit above the static middleware: the
middleware skips any response that already carries a `Content-Encoding`
(`compression/index.js` ~line 162), so pre-compressed `/assets` are untouched.

`PKURU_NO_COMPRESSION` is an ops kill switch. Rename it for the target project.
The change touches every page response and its interaction with the streamed
render is subtle, so being able to disable it by config rather than a revert is
worth the small config surface.

`compression@1.7.4` is gzip/deflate only. Gzip is the ten-fold win; brotli would
take the document from ~60 KB to ~40 KB and needs a newer release or a different
package. Check a release's changelog rather than assuming brotli support.

Do **not** move this to an nginx ingress instead. Its gzip filter and proxy
buffering know nothing about React's flush points and can recreate the held
shell somewhere harder to see.

## Change 2: make the stream class safe under compression (`server/PreloadInsertingStreamNode.mjs`)

This is the one that bites. Without it, mounting `compression()` deadlocks every
SSR response: the body arrives and the connection never closes.

```diff
   _write(chunk, encoding, callback) {
     let scriptTags = this._generateNewScriptTagsSinceLastCall();
     if (scriptTags.length > 0) {
       this._writable.write(scriptTags);
     }
-    this._writable.write(chunk, encoding, callback);
+    this._writable.write(chunk, encoding);
+    callback();
   }
```

Why the original hangs: `compression` replaces `res.write` with a
**two-argument** `(chunk, encoding)` function that silently drops a third
argument. Handing it `callback` means this `Writable` is never told the write
finished, so it stops pulling from React after the first chunk.

Why the obvious repair also hangs: waiting for `res` to emit `drain` when
`write()` returns `false` does not work either. The middleware writes into its
own zlib stream, so when its `write()` reports backpressure it is zlib that is
full, not `res`, and `res` may never emit `drain`. The whole body arrives, but
`finish` never fires and `res.end()` is never called.

Acknowledging the write immediately means this stream applies no backpressure
upstream to React. That is acceptable here: the destination buffers, and an SSR
document is bounded at a few hundred kilobytes, not an open-ended stream.

Keep `flush()` as it is; it is the link React uses.

## Change 3: immutable caching for hashed assets (`server.js`)

```diff
   expressStaticGzip(resolve("dist/client/assets"), {
     enableBrotli: true,
     orderPreference: ["br", "gz"],
     index: false,
+    serveStatic: { maxAge: "1y", immutable: true },
   })
```

Every file under `/assets` carries a content hash, so a URL can never change.
`serve-static` defaults to `max-age=0`, which made returning visitors revalidate
every module file on every navigation. `express-static-gzip@2.1.7` forwards the
`serveStatic` section to `serve-static`.

Apply this **only** to the hashed `assets/` mount. Leave `no-cache` on the HTML
(set in the SSR handler; it must always name the current hashes) and on the
root-level `express.static` mount, which serves unhashed files such as `sw.js`
and the web manifest that must revalidate.

Before assuming a CDN or ingress serves these files, check the live headers.
Here they carried `x-powered-by: Express` and a Node-format `ETag`, and a miss
under `/assets` fell through to the SSR catch-all, which proved Express was the
origin and this option was the right place.

## Change 4: a Suspense boundary so a shell exists (`src/components/pages/PkuruLayout.res`)

Without this, compression is correct but there is nothing early to stream. The
pages read their preloaded query at the top of their component
(`usePreloaded`), and React treats everything above the first Suspense boundary
as the shell that `onShellReady` must wait for. With no boundary between the
page and the root, the shell *is* the page, and nothing leaves the server until
the data query has answered.

```diff
     <Layout viewer queryRefs=fragmentRefs>
       <GlobalQuery.DetectedLang />
-      <Router.Outlet />
+      <React.Suspense fallback={<div className="p-6 text-sm text-gray-500"> {t`Loading...`} </div>}>
+        <Router.Outlet />
+      </React.Suspense>
     </Layout>
```

Placement rules, both essential:

- **Put it in the persistent layout around the outlet, not in each page.** Client
  navigations run inside a transition (`v7_startTransition: true` on
  `RouterProvider` in `wrapper.tsx`; confirm the target project has it), and
  React never swaps an already-visible boundary for its fallback during a
  transition, so moving between pages keeps the old page on screen. A boundary
  mounted fresh by each page shows its fallback on every navigation. That flash
  is exactly why an earlier boundary in `WaitForMessages` was commented out.
- **The data is not fetched twice.** `RelaySSRUtils.makeServerFetchFunction`
  writes a `{"id": "<Query>{vars}", "final": false}` start marker into the shell
  when a server query begins, and `makeClientFetchFunction` subscribes to a
  replay subject for that id instead of refetching. Confirm the port still has
  this: the browser console prints `request <Query>… had ReplaySubject`.

The layout's own viewer query still sits above the boundary, so the shell waits
for that small query, not for the page's. That is the intended trade: the nav
needs the viewer.

Bots are unaffected. `entry/server.tsx` selects `onAllReady` for anything
`isbot()` flags, so crawlers still receive the complete page in one piece.

## Porting checklist

1. `compression` in `dependencies` (it was already present here, unused).
2. Change 2 first, then change 1. Never ship 1 without 2.
3. Change 3 on the hashed-assets mount only.
4. Confirm `v7_startTransition` and the `RelaySSRUtils` start-marker mechanism
   exist, then change 4 in the persistent layout.
5. **Rebuild both bundles.** `PreloadInsertingStreamNode` is inlined into
   `dist/server/server.js` at build time; a source edit has no effect on a
   running server until `build:server` runs. The layout change needs
   `build:client` as well, or hydration will not match.
6. Run the verification below locally, then again after deploy.

## Traps found while doing this

- **The stream class is bundled.** Every local test of "compression + the real
  page" ran the stale, deadlocking copy in `dist/server` until a rebuild. If a
  result contradicts a source change, check whether the bundle has it.
- **`isbot("Mozilla/5.0")` is `true`.** Any harness using a minimal UA hits the
  `onAllReady` path and can never observe a streamed shell. Use a full browser
  UA string when measuring streaming.
- **Time decoded content, not the first raw byte.** With a compressor the first
  byte on the socket is the 10-byte gzip header; the shell can still be stuck
  in zlib. Gunzip incrementally and timestamp when `<body` appears.
- **First request in a fresh process pays ~850 ms** of module loading regardless
  of encoding. Warm up before comparing.
- **Building with `VITE_API_ENDPOINT` set leaks it into client chunks.** Vite
  inlines the whole `import.meta.env` object where code references it. The
  client still used the relative `/graphql` at runtime, but rebuild the client
  without the override before leaving `dist` around.
- **`</html>` precedes streamed content.** `entry/server.tsx` writes the closing
  tags at shell time, so late Suspense content is appended after `</html>`.
  Browsers accept this and it predates these changes; noted so nobody "fixes" a
  probe that sees `</html>` early.
- **`v7_startTransition` was already on here.** If the target project lacks it, a
  layout boundary will flash on every client navigation; enable it first.

## Verification

### Headers, after deploy

```sh
curl -sD - -o /dev/null -H 'Accept-Encoding: gzip' -H 'User-Agent: Mozilla/5.0 (Macintosh) Chrome/128' https://<host>/<page> | grep -iE '^(content-encoding|vary|cache-control)'
# content-encoding: gzip · vary: Accept-Encoding · cache-control: no-cache
curl -sI https://<host>/assets/<any-hashed-file> | grep -iE '^(cache-control|content-encoding)'
# cache-control: public, max-age=31536000, immutable · content-encoding: br
```

### Decoded timeline probe

Proves the shell is readable before the page completes and that the gzip
framing decodes cleanly. Run against local or production.

```js
// node probe.mjs https://<host>/<page>
import https from "node:https"; import http from "node:http"; import zlib from "node:zlib";
const UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36";
const url = new URL(process.argv[2]); const t0 = performance.now(); const now = () => Math.round(performance.now() - t0);
const m = { firstByte: null, body: null, startMarker: null, fallback: null, content: null }; let text = "", wire = 0;
(url.protocol === "https:" ? https : http).get(url, { headers: { "accept-encoding": "gzip", "user-agent": UA } }, (res) => {
  const dec = res.headers["content-encoding"] === "gzip" ? zlib.createGunzip() : null;
  res.on("data", (c) => { wire += c.length; m.firstByte ??= now(); });
  const sink = dec ?? res; if (dec) res.pipe(dec);
  sink.on("data", (d) => { text += d;
    if (m.body === null && /<body/i.test(text)) m.body = now();
    if (m.startMarker === null && /"final":false/.test(text)) m.startMarker = now();
    if (m.fallback === null && /Loading\.\.\./.test(text)) m.fallback = now();
    if (m.content === null && /<div hidden id="S:/.test(text)) m.content = now(); });
  sink.on("end", () => console.log({ enc: res.headers["content-encoding"], wireKB: Math.round(wire / 1024), ...m, end: now() }));
});
```

Healthy output has `body`, `startMarker` and `fallback` within a few tens of
milliseconds, `content` (React's hidden boundary payload) later, and `enc: gzip`.

### Proving the gap is real

Production data is fast enough that shell and content are only ~200 ms apart.
To make the streaming unmistakable, put a proxy between the SSR and GraphQL
that delays **only the page's query** (match the operation name in the body) by
2 s and leaves the layout's viewer query alone; the shell should still land at
tens of milliseconds while the content waits the full delay. The SSR endpoint is
baked in at build time from `VITE_API_ENDPOINT` (`server/NetworkUtils.res`), so
this needs a `build:server` with the override pointing at the proxy port, and
another build afterwards to restore it. Compare with `PKURU_NO_COMPRESSION=1`
for a control: the two timelines should have the same shape.

### In a browser, after deploy

- Console shows `[debug] request EventsQuery… had ReplaySubject` and no
  hydration warnings.
- Network tab shows one `EventsQuery`, not two.
- Navigating between pages shows no "Loading…" flash; a hard reload shows the
  frame first, then the page.

## Rollback

Setting `PKURU_NO_COMPRESSION=1` disables compression without a deploy; changes
2 through 4 are harmless without it. Reverting change 4 alone returns to
one-shot rendering with compression still on. Reverting change 2 while change 1
is mounted is the only combination that breaks: every page hangs.
