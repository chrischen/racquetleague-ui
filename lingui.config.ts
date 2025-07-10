import type { LinguiConfig } from "@lingui/conf";

const config: LinguiConfig = {
  locales: ["en", "ja"],
  compileNamespace: "ts",
  fallbackLocales: {
    default: "en",
  },
  catalogs: [
    // {
    //   "path": "<rootDir>/src/locales/{locale}/molecules/{name}",
    //   "include": ["<rootDir>/src/components/molecules/{name}"],
    //   "exclude": ["**/*.tsx", "**/*.res", "**/*.ts"],
    // },
    // {
    //   "path": "<rootDir>/src/locales/{locale}/organisms/{name}",
    //   "include": ["<rootDir>/src/components/organisms/{name}"],
    //   "exclude": ["**/*.tsx", "**/*.res", "**/*.ts"],
    // },
    // {
    //   "path": "<rootDir>/src/locales/{locale}/pages/{name}",
    //   "include": ["<rootDir>/src/components/pages/{name}"],
    //   "exclude": ["**/*.tsx", "**/*.res", "**/*.ts"],
    // },
    // {
    //   // path: "src/locales/{locale}/messages",
    //   // include: ["src"],
    //   "path": "src/locales/pages/{locale}/{name}",
    //   "include": ["src/components/pages/{name}"]
    // },
    // {
    //   path: "src/locales/{locale}/messages",
    //   include: ["src"],
    //
    // }
  ],
  // "catalogsMergePath": "src/locales/{locale}",
  experimental: {
    extractor: {
      /// ...
      // glob pattern of entrypoints
      // this will find all nextjs pages
      entries: [
        "<rootDir>/src/components/routes/**/*.mjs",
        "<rootDir>/src/components/pages/**/*.mjs",
        "<rootDir>/src/components/organisms/**/*.mjs",
      ],
      // output pattern, this instruct extractor where to store catalogs
      // src/pages/faq.tsx -> src/pages/locales/faq/en.po
      output: "<rootDir>/src/locales/{entryDir}/{entryName}/{locale}",
      resolveEsbuildOptions: (options: import("esbuild").BuildOptions) => {
        options.resolveExtensions = [
          ".ts",
          ".js",
          ".jsx",
          ".tsx",
          ".mjs",
          ".webp",
        ];
        // Add loader for .webp files as dataurl (or file, depending on your needs)
        options.loader = {
          ...(options.loader || {}),
          ".webp": "dataurl",
        };

        return options;
      },
    },
  },
};

export default config;
