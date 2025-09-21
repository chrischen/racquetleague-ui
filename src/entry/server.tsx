import React from "react";
import type { ReactNode } from "react";
import ReactDOMServer from "react-dom/server";
import type { StaticHandlerContext } from "react-router-dom/server";
import {
  createStaticHandler,
  createStaticRouter,
} from "react-router-dom/server";
import { matchRoutes } from "react-router-dom";
import type { Request, Response } from "express";
import type { HelmetData, HelmetServerState } from "react-helmet-async";
import isbot from "isbot";
import parse from "html-react-parser";
import { HelmetProvider } from "react-helmet-async";
// import { collect } from "@linaria/server";
import { i18n } from "@lingui/core";
import { I18nProvider } from "@lingui/react";
import { RelayEnvironmentProvider } from "react-relay";
import { makeServer } from "./RelayEnv.re.mjs";
import Html, { Head } from "./Html";
import PreloadInsertingStreamNode from "../../server/PreloadInsertingStreamNode.mjs";
import { createFetchRequest } from "./fetch";
import type { RouteObject } from "react-router-dom"
import { routes as routesRl } from "../routes";
import { routes as routesJpl } from "../routes-jpl";
// import { wrapRoutesWithErrorBoundary } from "../routesWrapper";
import { Wrapper } from "../wrapper.tsx";

interface CriticalCss {
  critical: string;
  other: string;
  slug: string;
}
export interface HtmlProps {
  blockingCss?: string;
  helmet: HelmetData;
  html: string;
  root: React.ReactElement;
  scripts: string[];
  muiStyles?: Array<React.ReactElement>;
  window?: {
    [key: string]: object;
  };
}


interface ManifestEntry {
  file: string;
  src: string;
  isEntry?: boolean;
  isDynamicEntry?: boolean;
  css?: string[];
  assets?: string[];
  imports?: string[];
  dynamicImports?: string[];
}
interface Manifest {
  [key: string]: ManifestEntry;
}
type AssetChunk = {
  js: Set<string>;
  css: Set<string>;
};
const resolveAssets = (
  manifest: Manifest,
  path: keyof typeof manifest
): AssetChunk => {
  const entry = manifest[path];
  const current: AssetChunk = {
    js: entry.file ? new Set([entry.file]) : new Set(),
    css: entry.css ? new Set(entry.css) : new Set(),
  };
  const children: AssetChunk = entry.imports
    ? entry.imports.reduce(
      (acc: { js: Set<string>; css: Set<string> }, childPath: string) => {
        const children = resolveAssets(manifest, childPath);
        return {
          js: new Set([...acc.js, ...children.js]),
          css: new Set([...acc.css, ...children.css]),
        };
      },
      { js: new Set<string>(), css: new Set<string>() }
    )
    : { js: new Set(), css: new Set() };

  return {
    js: new Set<string>([...current.js, ...children.js]),
    css: new Set<string>([...current.css, ...children.css]),
  };
};

const prependSlash = (s: string) => (import.meta.env.BASE_URL ?? "/") + s;
const getHtml = (
  helmetContext: { helmet?: HelmetServerState },
  headTags?: string,
  blockingCss?: string[],
  preload?: string[],
  scripts?: string[]
): [string, string] => {
  let viteTags: ReactNode;
  if (import.meta.env.DEV && headTags) {
    viteTags = parse(headTags);
  } else if (headTags) {
    headTags = headTags.replace(/<script [^>]*><\/script>/s, "");

    viteTags = parse(headTags);
  }

  const html = (
    <Html
      head={
        <Head helmet={helmetContext.helmet}>
          {blockingCss
            ? blockingCss.map((src, i) => <link key={i} rel="stylesheet" href={src} />)
            : null}
          {viteTags}
          {preload?.map((href, i) => {
            return <link key={i} rel="modulepreload" href={href} />;
          })}
          {scripts?.map((script) => {
            return <script type="module" src={script} async />;
          })}
        </Head>
      }
    ></Html>
  );
  const doctype = "<!DOCTYPE html>";
  const htmlStr = (doctype + ReactDOMServer.renderToStaticMarkup(html)).split(
    '<div id="root">',
    2
  );
  return [htmlStr[0] + '<div id="root">', htmlStr[1]];
};

export async function render(
  req: Request,
  res: Response,
  url: string,
  bootstrap?: string,
  viteHead?: string,
  manifest?: Manifest
): Promise<CriticalCss | undefined | void> {
  // Relay store and environment should be recreated for each request
  // const store = createStore();
  // const environment = createEnvironment({ configName: "server", store });

  // Overwride web server output stream to inject additional data to React
  // output
  const transformStream = new PreloadInsertingStreamNode(res);
  // Set the Relay store to be used in the stream class
  // transformStream.setStore(store);
  transformStream.on("finish", () => {
    res.end();
  });

  let routes: RouteObject[];
  if (req.headers?.host === "local.japanpickleleague.com:3000"
    || req.headers?.host === "www.japanpickleleague.com") {
    routes = routesJpl;
  } else {
    routes = routesRl;
  }
  
  // Wrap routes with error boundary for consistent error handling
  // const routesWithErrorBoundary = wrapRoutesWithErrorBoundary(routes);
  
  const environment = makeServer(transformStream.onQuery.bind(transformStream), req);
  /* React Router */
  const handler = createStaticHandler(routes);
  const fetchRequest = createFetchRequest(req);
  const context = await handler.query(fetchRequest, {
    requestContext: {
      environment,
    },
  });

  if (
    context instanceof Response &&
    [301, 302, 303, 307, 308].includes(context.status)
  ) {
    const loc = context.headers.get("Location");
    return res.redirect(context.status, loc ?? "/");
  }

  const router = createStaticRouter(
    handler.dataRoutes,
    context as StaticHandlerContext
  );

  const route = matchRoutes(routes, url);
  let css: string[] = [];
  let scripts: string[] = [];
  let preloadScripts: string[] = [];
  // let preload: string[] = [];
  if (manifest && route) {
    const assets = route.reduce(
      (acc, { route }) => {
        const assets = resolveAssets(manifest, route.handle);
        return {
          js: new Set([...acc.js, ...assets.js]),
          css: new Set([...acc.css, ...assets.css]),
        };
      },
      { js: new Set<string>(), css: new Set<string>() }
    );
    const entry = resolveAssets(manifest, "index.html");

    preloadScripts = [...assets.js, ...entry.js];
    scripts = Array.from(entry.js);
    css = [...assets.css, ...entry.css];
  } else if (route) {
    preloadScripts = [route[0].route.handle];
  }

  const streaming = !isbot(req.header("User-Agent"));
  let didError = false;

  let cachedHtml: [string, string];

  const helmetContext: { helmet: HelmetServerState | undefined } = {
    helmet: undefined,
  };
  const app = (
    <React.StrictMode>
      <RelayEnvironmentProvider environment={environment}>
        <HelmetProvider context={helmetContext}>
          <Wrapper
            router={router}
            context={context as StaticHandlerContext}
          />
        </HelmetProvider>
      </RelayEnvironmentProvider>
    </React.StrictMode>
  );

  const stream = ReactDOMServer.renderToPipeableStream(app, {
    bootstrapModules: (bootstrap ? [...scripts, bootstrap] : scripts).map(prependSlash),
    bootstrapScriptContent:
      "window.__READY_TO_BOOT ? window.__BOOT() : (window.__READY_TO_BOOT = true)",
    onShellReady() {
      // The content above all Suspense boundaries is ready.
      // If something errored before we started streaming, we set the error code appropriately.
      // Set the return type to `text/html`, and dump the response back to
      // the client

      res.statusCode = didError ? 500 : 200;
      res.setHeader("Content-type", "text/html");

      cachedHtml = getHtml(
        helmetContext,
        viteHead,
        css.map(prependSlash),
        preloadScripts.map(prependSlash),
        []
      );

      res.write(cachedHtml[0]);
      if (streaming) {
        stream.pipe(transformStream);
        transformStream.write(cachedHtml[1]);
      }
    },
    // onShellError(_error) {
    //   // Something errored before we could complete the shell so we emit an alternative shell.
    //   // @TODO: This gives a write after end error
    //   res.statusCode = 500;
    //   res.send(
    //     '<!doctype html><p>Loading...</p><script src="clientrender.js"></script>'
    //   );
    // },
    onAllReady() {
      // If you don't want streaming, use this instead of onShellReady.
      // This will fire after the entire page content is ready.
      // You can use this for crawlers or static generation.
      // res.statusCode = didError ? 500 : 200;
      // res.setHeader('Content-type', 'text/html');

      if (!streaming) {
        stream.pipe(transformStream);
        // Close the HTML tags
        res.write(cachedHtml[1]);
      }
    },
    onError(err) {
      didError = true;
      console.error(err);
    },
  });

  return { critical: "", other: "", slug: "" };
}
