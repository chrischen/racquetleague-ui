// Lazy loader for the HiGHS mixed-integer solver (WebAssembly).
//
// Written in TypeScript rather than a ReScript `%raw` so that Vite can see the
// dynamic imports and the worker statically, and emit the solver plus its
// ~3.4 MB `.wasm` as their own chunk. Nothing here is evaluated until a solver
// strategy is used for the first time, so app startup never waits on it.
//
// Two backends, in order of preference:
//
//   worker      — the solve runs off the main thread, so a ten-round
//                 generation costs the UI nothing.
//   in-process  — the same module on the main thread. Used under Node (vitest,
//                 SSR), and as a fallback anywhere a worker cannot start.
//
// The worker is *validated* before being adopted (see `probe`), because a
// worker that fails to boot — CSP, a bundling quirk, an old browser — should
// degrade to a working solver rather than to no solver.

import { instantiate, type HighsModule, type HighsSolveResult } from "./highsWasmUrl";

export type { HighsSolveResult };

export type HighsBackend = {
  solve(
    lp: string,
    options: Record<string, unknown>,
  ): Promise<HighsSolveResult>;
  // Present only on the worker backend, so a failed probe can tear it down.
  terminate?(): void;
};

// Feature gate. Callers hide the solver strategies entirely when this is false.
export function isAvailable(): boolean {
  return (
    typeof WebAssembly === "object" &&
    typeof WebAssembly.instantiate === "function"
  );
}

// Smallest possible model: proves the backend can actually load the wasm and
// return a solution before we commit to it.
const PROBE_LP = "Minimize\n obj: x0\nSubject To\n c0: x0 >= 1\nBinary\n x0\nEnd\n";

function createInProcessBackend(): HighsBackend {
  let modulePromise: Promise<HighsModule> | null = null;
  const getModule = () => {
    if (!modulePromise) {
      modulePromise = instantiate().catch((error) => {
        modulePromise = null;
        throw error;
      });
    }
    return modulePromise;
  };
  return {
    solve: async (lp, options) => (await getModule()).solve(lp, options),
  };
}

type Pending = {
  resolve: (result: HighsSolveResult) => void;
  reject: (error: Error) => void;
};

function createWorkerBackend(): HighsBackend | undefined {
  if (typeof Worker === "undefined") return undefined;
  let worker: Worker;
  try {
    worker = new Worker(new URL("./highsWorker.ts", import.meta.url), {
      type: "module",
    });
  } catch {
    return undefined;
  }

  const pending = new Map<number, Pending>();
  let nextId = 0;

  worker.onmessage = (
    event: MessageEvent<{ id: number; result?: HighsSolveResult; error?: string }>,
  ) => {
    const entry = pending.get(event.data.id);
    if (!entry) return;
    pending.delete(event.data.id);
    if (event.data.error !== undefined) entry.reject(new Error(event.data.error));
    else entry.resolve(event.data.result as HighsSolveResult);
  };

  // A worker-level failure kills every request in flight, not just one.
  worker.onerror = () => {
    pending.forEach((entry) => entry.reject(new Error("HiGHS worker failed")));
    pending.clear();
  };

  return {
    solve: (lp, options) =>
      new Promise<HighsSolveResult>((resolve, reject) => {
        const id = nextId++;
        pending.set(id, { resolve, reject });
        worker.postMessage({ id, lp, options });
      }),
    terminate: () => worker.terminate(),
  };
}

let cached: Promise<HighsBackend> | null = null;

async function selectBackend(): Promise<HighsBackend> {
  const workerBackend = createWorkerBackend();
  if (workerBackend) {
    try {
      await workerBackend.solve(PROBE_LP, { output_flag: false });
      return workerBackend;
    } catch (error) {
      console.warn("[highs] worker unavailable, solving on the main thread:", error);
      workerBackend.terminate?.();
    }
  }
  const inProcess = createInProcessBackend();
  // Surface an unusable wasm now rather than on the first real solve.
  await inProcess.solve(PROBE_LP, { output_flag: false });
  return inProcess;
}

export function loadHighs(): Promise<HighsBackend> {
  if (!cached) {
    cached = selectBackend().catch((error) => {
      // Don't cache the failure: a later attempt should be able to retry.
      cached = null;
      throw error;
    });
  }
  return cached;
}

// True once a backend is resident, so the UI can skip the "Preparing optimizer"
// label on subsequent generations.
export function isLoaded(): boolean {
  return cached !== null;
}
