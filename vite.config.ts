/// <reference types="vitest" />
import { defineConfig } from "vite";
// import react from "@vitejs/plugin-react-swc";
import react from "@vitejs/plugin-react";
import wyw from '@wyw-in-js/vite';
import { lingui } from "@lingui/vite-plugin";
import relay from "vite-plugin-relay";
import { splitVendorChunkPlugin } from "vite";
import { compression } from "vite-plugin-compression2";
import { visualizer } from "rollup-plugin-visualizer";

// https://vitejs.dev/config/

/*
// Babel based setup
export default defineConfig({
  plugins: [
    react({
      babel: { plugins: ["relay", "macros"] },
    }),
    wyw(),
    lingui(),
  ],
}); */
export default defineConfig({
  base: process.env.PUBLIC_PATH ? process.env.PUBLIC_PATH : "/",
  ssr: {
    target: "node",
    noExternal: process.env.NODE_ENV === "production" ? ["react-relay", "react-imgix", "react-google-autocomplete", "k-means-clustering-js"] : ["k-means-clustering-js"], // @NOTE: This option breaks SSR dev server
  },
  build: {
    sourcemap: true,
    manifest: true,
    minify: true,
    rollupOptions: {
      output: {
        format: "esm",
        /* manualChunks: {
          react: ["react", "react-dom"],
          relay: ["react-relay", "relay-runtime"],
        }, */
      },
      plugins: [visualizer({ open: false })],
    },
  },
  test: {
    environment: "jsdom", // or 'jsdom', 'node'
    exclude: ["tests/e2e/**", "node_modules/**"],
    setupFiles: ['test/setupTestFramework.ts'],
    globals: true
  },
  legacy: {
    proxySsrExternalModules: true
  },
  plugins: [
    splitVendorChunkPlugin(),
    react({
      include: /\.(js|jsx|ts|tsx|mjs)$/,
      // Config for Babel
      babel: {
        plugins: ["macros"]
      },
      // Config if SWC is used instead of babel
      plugins: [
        [
          "@lingui/swc-plugin",
          {
            /* runtimeModules: {
              i18n: ["@lingui/core", "i18n"],
              trans: ["@lingui/react", "Trans"],
            }, */
          },
        ],
      ],
    }),
    wyw({ preprocessor: "none" }),
    lingui(),
    relay,
    /* visualizer({
      template: "treemap", // or sunburst
      open: false,
      gzipSize: true,
      brotliSize: true,
      filename: "bundle.html", // will be saved in project's root
      sourcemap: false
    }), */
    /* Not strictly necessary as CDN deployment will compress static assets. */
    /* process.env.NODE_ENV === "production"
      ? compression({
          algorithm: "brotliCompress",
          exclude: [/\.(br)$/, /\.(gz)$/],
          deleteOriginalAssets: false,
        })
      : undefined, */
    compression({ algorithm: 'gzip', exclude: [/\.(br)$/, /\.(gz)$/], deleteOriginalAssets: false }),
    compression({ algorithm: 'brotliCompress', exclude: [/\.(br)$/, /\.(gz)$/], deleteOriginalAssets: false }),
  ],
  resolve: {
    // extensions: [".js", ".mjs", ".tsx", ".ts", ".jsx"],
  }
});
