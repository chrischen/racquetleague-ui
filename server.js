import fs from "node:fs";
import url from "url";
import path from "node:path";
import cors from "cors";
import { fileURLToPath } from "node:url";
import express from "express";
import favicon from "serve-favicon";
import compression from "compression";

// Needed to process node imports without file extensions
import "extensionless/register";
import expressStaticGzip from "express-static-gzip";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const isTest = process.env.VITEST;

process.env.MY_CUSTOM_SECRET = "API_KEY_qwertyuiop";

const cssCache = {};
let compiledCss;
let enableCriticalCss = false;

function addProtocol(pathUrl) {
  return pathUrl.startsWith("//") ? `https:${pathUrl}` : pathUrl;
}
function getAssetPath(publicPath) {
  const { pathname, protocol } = url.parse(addProtocol(publicPath));
  return protocol && pathname ? pathname : encodeURI(publicPath);
}

// Dev only: while a dev scenario is active (dev/scenarios/README.md), pin a
// badge to the corner so a mocked page is never mistaken for real data. It is
// appended to <body>, outside #root, so hydration never sees it.
const SCENARIO_BADGE = `<script>(function () {
  var m = document.cookie.match(/(?:^|; )pkuru_scenario=([^;]+)/);
  if (!m) return;
  function add() {
    var name = decodeURIComponent(m[1]).replace(/[^a-z0-9_-]/gi, "");
    var badge = document.createElement("div");
    badge.id = "pkuru-scenario-badge";
    badge.style.cssText = "position:fixed;left:8px;bottom:8px;z-index:2147483647;background:#b91c1c;color:#fff;font:12px/1 system-ui,sans-serif;padding:6px 10px;border-radius:6px;opacity:.92;box-shadow:0 1px 4px rgba(0,0,0,.3)";
    var label = document.createElement("a");
    label.href = "/__dev/scenario";
    label.textContent = "Scenario: " + name;
    label.style.cssText = "color:#fff;text-decoration:none";
    var exit = document.createElement("a");
    exit.href = "/__dev/scenario/off?to=" + encodeURIComponent(location.pathname + location.search);
    exit.textContent = "exit";
    exit.style.cssText = "color:#fff;text-decoration:underline;margin-left:8px";
    badge.appendChild(label);
    badge.appendChild(exit);
    document.body.appendChild(badge);
  }
  if (document.body) add(); else document.addEventListener("DOMContentLoaded", add);
})();</script>`;

const requestPath = process.env.PUBLIC_PATH
  ? getAssetPath(process.env.PUBLIC_PATH)
  : "/";

export async function createServer(
  root = process.cwd(),
  isProd = process.env.NODE_ENV === "production",
  hmrPort
) {
  let routeManifest;
  if (isProd) {
    routeManifest = JSON.parse(
      fs.readFileSync("./dist/client/.vite/manifest.json", "utf8")
    );
  }

  const resolve = (p) => path.resolve(__dirname, p);

  const indexProd = isProd
    ? fs.readFileSync(resolve("dist/client/index.html"), "utf-8")
    : "";

  const app = express();

  // The SSR response was going out uncompressed: 655 KB on the wire for
  // /e/pickleball, which gzip takes to about 60 KB.
  //
  // This is safe with the streamed render below even though a compressor
  // normally buffers until it has a full block, which would hold the shell
  // until the first Suspense boundary resolves. React's Node renderer calls
  // `destination.flush()` after each write when the destination defines one,
  // PreloadInsertingStreamNode.flush() forwards that to the response, and this
  // middleware is what gives the response a flush() to forward to. Without it
  // mounted, that chain ends in a no-op. Measured with a 1.5s boundary: shell
  // readable at 3ms with this, 1514ms with a compressor that ignores flushes.
  //
  // Pre-compressed /assets are unaffected: compression skips any response that
  // already carries a Content-Encoding.
  //
  // PKURU_NO_COMPRESSION is an ops kill switch. This touches every page
  // response and its interaction with the streamed render is subtle (see the
  // long note in PreloadInsertingStreamNode._write), so it is worth being able
  // to turn off by config rather than by shipping a revert.
  if (!process.env.PKURU_NO_COMPRESSION) app.use(compression());

  app.use(favicon(path.join(__dirname, 'src', 'assets', 'favicon.ico')));

  var corsOptions = {
    origin: ['https://www.racquetleague.com', 'https://www.japanpickleleague.com', 'https://www.pkuru.com'],
    optionsSuccessStatus: 200 // some legacy browsers (IE11, various SmartTVs) choke on 204
  }
  /**
   * @type {import('vite').ViteDevServer}
   */
  let vite;
  if (!isProd) {
    vite = await (
      await import("vite")
    ).createServer({
      root,
      logLevel: isTest ? "error" : "info",
      server: {
        middlewareMode: true,
        watch: {
          // During tests we edit the files too fast and sometimes chokidar
          // misses change events, so enforce polling for consistency
          usePolling: true,
          interval: 100,
        },
        hmr: {
          port: hmrPort,
        },
      },
      appType: "custom",
    });

    // Dev scenarios (dev/scenarios/README.md): a cookie or header picks a
    // named fake backend for /graphql, so hard-to-reach UI states can be
    // opened in the real app. SSR is pointed back at this server so the
    // server render sees the same scenario as the browser. With no scenario
    // selected, /graphql falls through untouched to Vite's proxy below; any
    // middleware added here must not read the /graphql body before next(),
    // or the proxied request hangs.
    process.env.SSR_API_ENDPOINT ??= "http://localhost:3000/graphql";
    const { createScenarioMiddleware } = await import("./dev/scenario/middleware.mjs");
    const scenario = createScenarioMiddleware({
      scenariosDir: resolve("dev/scenarios"),
      schemaPath: resolve("data/schema.graphql"),
      upstream: (process.env.API_PROXY_TARGET || "http://localhost:4555") + "/graphql",
    });
    app.use(scenario.routes);
    app.use(scenario.graphql);

    // use vite's connect instance as middleware
    app.use(vite.middlewares);
  } else {
    // app.use(requestPath + "assets", express.static("dist/client/assets"));
    app.use(
      requestPath + "assets",
      cors(corsOptions),
      expressStaticGzip(resolve("dist/client/assets"), {
        enableBrotli: true,
        orderPreference: ["br", "gz"],
        index: false,
        // Everything under /assets carries a content hash in its filename, so a
        // given URL can never change and the browser may keep it for as long as
        // it likes. The serve-static default is max-age=0, which made returning
        // visitors revalidate all ~100 module files on every navigation. The
        // HTML stays no-cache (set in the SSR handler), so it always names the
        // current hashes; the root-level mount below is left alone because it
        // serves unhashed files (sw.js, the web manifest) that must revalidate.
        serveStatic: { maxAge: "1y", immutable: true },
      })
    );
    /* app.use(
      (await import("serve-static")).default(resolve("dist/client"), {
        index: false,
      })
    ); */

    // Cached CSS from Linaria
    app.get("/styles/:slug", (req, res) => {
      res.type("text/css");
      res.end(cssCache[req.params.slug]);
    });

    // Serve root-level public files (sw.js, manifest.webmanifest, icons/, etc.)
    app.use(
      requestPath,
      express.static(resolve("dist/client"), {
        index: false,
      })
    );
  }

  // DinkHunt labeler UI — a prebuilt bundle linked in at image build time
  // (scripts/copy-labeler-dist.sh -> labeler-dist/, gitignored; the labeler
  // project itself stays isolated in ../dinkhunt). Mounted BEFORE the SSR
  // catch-all so /labeler never falls through to the router. Its API is the
  // separate labeler service at /labeler-api; auth is the same-origin
  // better-auth cookie, so no token setup for browser users.
  const labelerDist = resolve("labeler-dist");
  if (fs.existsSync(labelerDist)) {
    app.use(
      "/labeler",
      expressStaticGzip(labelerDist, {
        index: false,
      })
    );
    // SPA fallback: /labeler and any client-side subroute get the shell.
    app.get(["/labeler", "/labeler/*"], (req, res) => {
      // Same rationale as the SSR handler: the shell must revalidate so it
      // never references dead asset hashes after a deploy.
      res.setHeader("Cache-Control", "no-cache");
      res.sendFile(path.join(labelerDist, "index.html"));
    });
  }

  // loading render function needs to be moved out of the request handler due
  // to unknown bug with ssrLoadModule if it gets called again (such as on
  // page reload)
  app.use("*", async (req, res) => {
    // HTML must always revalidate so stale markup (with old asset hashes)
    // never survives a deploy; static assets are served by earlier middleware
    res.setHeader("Cache-Control", "no-cache");
    try {
      const url = req.originalUrl;

      let template;
      let render;
      if (!isProd) {
        // always read fresh template in dev
        template = fs.readFileSync(resolve("index.html"), "utf-8");
        template = await vite.transformIndexHtml(url, template);
        render = (await vite.ssrLoadModule("/src/entry/server.tsx")).render;
      } else {
        template = indexProd;
        render = (await import("./dist/server/server.js")).render;
      }

      let head = "";
      if (!isProd) {
        head = template.match(/<head>(.+?)<\/head>/s)[1];
        // Re-inject fast-refresh script but with "async" tag so that it runs
        // first
        head += `<script type="module" async>import RefreshRuntime from "/@react-refresh"
RefreshRuntime.injectIntoGlobalHook(window)
window.$RefreshReg$ = () => {}
window.$RefreshSig$ = () => (type) => type
window.__vite_plugin_react_preamble_installed__ = true;</script>`;
        head += SCENARIO_BADGE;
        // head += '<script type="module" src="/src/entry/client.tsx" async></script>';
      }

      // Detection is being done using the stats file in production
      let bootstrap;
      // if (isProd)
      // bootstrap =
      //     "assets/" +
      //     fs
      //       .readdirSync("./dist/client/assets")
      //       .filter((fn) => fn.includes("index") && fn.endsWith(".js"))[0];
      // else
      if (!isProd)
        bootstrap = "src/entry/client.tsx";

      const context = {};
      const criticalCss = await render(
        req,
        res,
        url,
        bootstrap,
        head,
        routeManifest
      );

      if (criticalCss) {
        // Cache the non-critical CSS for serving
        cssCache[criticalCss.slug] = criticalCss.other;
      }

      // @TODO: React router changed how context/redirect is done
      // ...
      if (context.url) {
        // Somewhere a `<Redirect>` was rendered
        return res.redirect(301, context.url);
      }
    } catch (e) {
      !isProd && vite.ssrFixStacktrace(e);
      console.log(e.stack);
      res.status(500).end(e.stack);
    }
  });

  return { app, vite };
}

if (!isTest) {
  createServer().then(({ app, vite }) =>
    app.listen(3000, () => {
      console.log("http://localhost:3000");
    })
  );
}
