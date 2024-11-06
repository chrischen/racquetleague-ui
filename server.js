import fs from "node:fs";
import url from "url";
import path from "node:path";
import cors from "cors";
import { fileURLToPath } from "node:url";
import express from "express";

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
  }
  // loading render function needs to be moved out of the request handler due
  // to unknown bug with ssrLoadModule if it gets called again (such as on
  // page reload)
  app.use("*", async (req, res) => {
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
