// Vitest config for the role-probe experiment only (see scripts/role-probe.ts).
// Same shape as lab-precompute.config.ts: a batch job, never part of `yarn test`.
import { mergeConfig } from "vite";
import base from "../vite.config";

export default mergeConfig(base, {
  test: {
    include: ["scripts/role-probe.ts"],
    exclude: [],
    testTimeout: 0,
    hookTimeout: 0,
    pool: "forks",
    poolOptions: { forks: { singleFork: true } },
  },
});
