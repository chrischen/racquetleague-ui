// Runs HiGHS off the main thread.
//
// `highs.solve` is synchronous WebAssembly: a single round is 100-250 ms of
// uninterruptible work, and a ten-round generation is that ten times over. On
// the main thread no amount of yielding hides it — the page simply stutters. In
// here it costs the UI nothing.
//
// The boundary is deliberately thin: LP text in, solution out. All the model
// building and decoding stays in ReScript on the main thread, so nothing about
// the solver's logic is duplicated here.

import { instantiate, type HighsModule } from "./highsWasmUrl";

type SolveRequest = {
  id: number;
  lp: string;
  options: Record<string, unknown>;
};

let modulePromise: Promise<HighsModule> | null = null;

const getModule = (): Promise<HighsModule> => {
  if (!modulePromise) {
    modulePromise = instantiate().catch((error) => {
      // Don't cache the failure; a later request may succeed.
      modulePromise = null;
      throw error;
    });
  }
  return modulePromise;
};

self.onmessage = async (event: MessageEvent<SolveRequest>) => {
  const { id, lp, options } = event.data;
  try {
    const highs = await getModule();
    self.postMessage({ id, result: highs.solve(lp, options) });
  } catch (error) {
    self.postMessage({ id, error: String(error) });
  }
};
