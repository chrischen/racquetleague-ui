// Typed wrapper around the HiGHS WASM solver.
//
// The backend selection (worker vs main thread), wasm lifecycle and asset
// location all live in `highsLoader.ts`; this module only adds types and error
// handling.

type highs

type solveOptions = {
  time_limit?: float,
  // Every objective coefficient we emit is an integer, so any two distinct
  // feasible objectives differ by at least 1. An absolute gap below 1 therefore
  // proves optimality, and a zero relative gap stops HiGHS from stopping early
  // on the large court-reward term (see the penalty tiers in `SolverRound`).
  mip_abs_gap?: float,
  mip_rel_gap?: float,
  presolve?: string,
  output_flag?: bool,
  log_to_console?: bool,
  random_seed?: int,
  threads?: int,
}

type column = {@as("Primal") primal: float}

type solveResult = {
  @as("Status") status: string,
  @as("ObjectiveValue") objectiveValue: float,
  @as("Columns") columns: Js.Dict.t<column>,
}

@module("./highsLoader") external isAvailable: unit => bool = "isAvailable"
@module("./highsLoader") external isLoaded: unit => bool = "isLoaded"
@module("./highsLoader") external loadHighsRaw: unit => promise<highs> = "loadHighs"

// Asynchronous because the solve may be running in a worker.
@send external solveRaw: (highs, string, solveOptions) => promise<solveResult> = "solve"

// `None` when no backend can be brought up at all (unsupported runtime, blocked
// asset, out of memory). Callers fall back to the greedy path.
let load = async (): option<highs> =>
  if !isAvailable() {
    None
  } else {
    try {
      Some(await loadHighsRaw())
    } catch {
    | exn =>
      Js.Console.error2("[HighsBindings] failed to load HiGHS:", exn)
      None
    }
  }

// HiGHS rejects on a malformed model; a bug in the LP writer must degrade to
// the greedy path rather than take the app down mid-event.
let solve = async (highs: highs, lp: string, options: solveOptions): option<solveResult> =>
  try {
    Some(await highs->solveRaw(lp, options))
  } catch {
  | exn =>
    Js.Console.error2("[HighsBindings] solve failed:", exn)
    None
  }

// Statuses we are willing to decode. A time-limited run still carries the best
// incumbent found, which is usually optimal or near it at these model sizes.
let isUsableStatus = (status: string): bool =>
  switch status {
  | "Optimal"
  | "Time limit reached"
  | "Iteration limit reached"
  | "Bound on objective reached"
  | "Target for objective reached" => true
  | _ => false
  }

let defaultOptions = (~timeLimit: float, ~seed: int): solveOptions => {
  time_limit: timeLimit,
  mip_abs_gap: 0.5,
  mip_rel_gap: 0.,
  output_flag: false,
  log_to_console: false,
  random_seed: seed,
}
