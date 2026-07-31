// Locating and instantiating the HiGHS wasm module.
//
// Shared by the main-thread loader and the worker so both resolve the asset the
// same way. Vite rewrites the `new URL(..., import.meta.url)` below at build
// time based on this file's location, so it works from either context.

export type HighsSolveResult = {
  Status: string;
  ObjectiveValue: number;
  Columns: Record<string, { Primal: number; Name?: string }>;
};

export type HighsModule = {
  solve(problem: string, options?: Record<string, unknown>): HighsSolveResult;
};

const isNodeRuntime = (): boolean =>
  typeof process !== "undefined" &&
  !!(process as { versions?: { node?: string } }).versions?.node;

export function locateWasm(): string | undefined {
  // Under Node (vitest, SSR) the emscripten glue finds highs.wasm next to
  // itself via __dirname, so overriding locateFile would only get in the way.
  if (isNodeRuntime()) return undefined;
  try {
    // In the browser the glue has no usable script directory inside an ESM
    // bundle and would fetch "highs.wasm" relative to the current route.
    return new URL(
      "../../../../node_modules/highs/build/highs.wasm",
      import.meta.url,
    ).href;
  } catch {
    // Fall back to the glue's own resolution rather than failing the load.
    return undefined;
  }
}

export async function instantiate(): Promise<HighsModule> {
  const wasmUrl = locateWasm();
  const loaderModule = await import("highs");
  const loader = (loaderModule as { default?: unknown }).default ?? loaderModule;
  return (loader as (o?: unknown) => Promise<HighsModule>)(
    wasmUrl ? { locateFile: () => wasmUrl } : {},
  );
}
