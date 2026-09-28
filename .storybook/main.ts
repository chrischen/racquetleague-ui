import type { StorybookConfig } from "@storybook/react-vite";

// Stories sit next to their components as <Component>.stories.tsx. Storybook
// reuses vite.config.ts, so the Lingui, Linaria (wyw-in-js) and Relay plugins
// behave exactly as they do in the app. See .storybook/relay.tsx for how
// stories get Relay data.
const config: StorybookConfig = {
  stories: ["../src/**/*.stories.@(ts|tsx)"],
  addons: ["@storybook/addon-a11y"],
  framework: {
    name: "@storybook/react-vite",
    options: {},
  },
  async viteFinal(config) {
    // Drop the app's build-only extras: the gzip/brotli copies of every asset
    // and the bundle visualizer, which would overwrite the app's stats.html.
    const skip = (p: unknown) =>
      typeof p === "object" && p !== null && "name" in p && /compression|visualizer/i.test(String(p.name));
    config.plugins = (config.plugins ?? []).flat().filter((p) => !skip(p));
    if (config.build?.rollupOptions) config.build.rollupOptions.plugins = [];
    // Vite 5.2's dev server caches file-existence checks by default (an
    // experimental feature). A story or wrapper created while Storybook runs
    // can then be served raw, untransformed, until a restart. Turn it off.
    config.server = { ...config.server, fs: { ...config.server?.fs, cachedChecks: false } };
    return config;
  },
};

export default config;
