// Vitest config for the saved-run generator only.
//
// `scripts/precompute-lab-run.ts` needs Vite's resolver to load the ReScript
// build output, but it is a build step rather than a test and must never run
// under `yarn test` — so it gets its own config rather than a skip guard in
// the suite. The app config supplies the plugins and aliases; everything here
// is about turning a test runner into a batch job: one file, no timeout, no
// parallelism inside the process (the orchestrator forks per seed instead).
import { mergeConfig } from "vite";
import base from "../vite.config";

export default mergeConfig(base, {
  test: {
    include: ["scripts/precompute-lab-run.ts"],
    exclude: [],
    testTimeout: 0,
    hookTimeout: 0,
    pool: "forks",
    poolOptions: { forks: { singleFork: true } },
  },
});
