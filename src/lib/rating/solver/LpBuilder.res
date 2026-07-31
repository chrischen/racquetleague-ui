// Turns priced candidates into CPLEX LP text for HiGHS.
//
// Formulation (weighted set partitioning, one round):
//
//   variables  x_i  1 if candidate match i is played
//              z_j  1 if player j plays this round (0 = bye)
//              s_k  1 if soft-required player k could not be seated
//
//   minimise   sum_i cost'_i x_i  -  sum_j benefit'_j z_j  +  sum_k penalty s_k
//
//   s.t.       sum_{i : j in i} x_i - z_j = 0     for every player j
//              sum_i x_i  = / <=  matchTarget
//              z_j = 1                            for every must-play player
//              z_j + s_k >= 1                     for every soft-required player
//
// Every coefficient is an integer, which is what lets the solver run with a
// sub-1 absolute MIP gap and still be provably optimal.
//
// **Keeping the coefficient range narrow is a performance requirement, not a
// tidiness one.** HiGHS works to a relative tolerance, so if the tiered
// penalties dwarf the ordinary cost differences the solver can barely tell two
// candidates apart and spends its whole time limit proving optimality. Two
// things keep the range small:
//
//   1. Anything that *can* be a hard constraint is one. Filling the courts, and
//      seating players who sat out last round, are expressible as constraints
//      whenever they are achievable — which is nearly always — so their penalty
//      tiers disappear from the objective entirely.
//   2. With `sum_i x_i` and therefore `sum_j z_j` fixed, subtracting a constant
//      from every cost and every benefit cannot change the argmin. Normalising
//      both to start at zero shrinks the objective to the *spread* of the costs
//      rather than their absolute size.
//
// Variables are named by index (`x12`, `z3`, `s0`) rather than by stable id:
// player ids are UUIDs, and embedding four of them per variable name would make
// the LP text an order of magnitude larger for no benefit. `lpModel` keeps the
// index -> entity mapping needed to decode the solution.

open Rating
open SolverTypes

type fillMode =
  | // sum x = n: the courts can provably all be filled.
  ExactFill(int)
  | // sum x <= n, with a per-match reward. Only used when the exact model comes
  // back infeasible (a gender-mixed filter or a pruned enumeration that cannot
  // partition the pool).
  AtMostFill(int, float)

type lpModel<'a> = {
  lp: string,
  candidates: array<candidate<'a>>, // index i <-> x_i
  players: array<Player.t<'a>>, // index j <-> z_j
  softRequiredPlayerIndices: array<int>, // index k <-> s_k, value is a player index
  mustPlayPlayerIndices: array<int>,
  fill: fillMode,
  // Constants folded out of the objective by normalisation. Added back when
  // reporting an objective value, so callers see a comparable number.
  costOffset: float,
  benefitOffset: float,
  numVariables: int,
  numConstraints: int,
}

// ---------------------------------------------------------------------------
// Text buffer
// ---------------------------------------------------------------------------

// LP readers are historically line-length limited, so expressions are wrapped.
let termsPerLine = 10

type buffer = {
  chunks: array<string>,
  mutable termsOnLine: int,
}

let makeBuffer = (): buffer => {chunks: [], termsOnLine: 0}

let line = (b: buffer, s: string) => {
  b.chunks->Array.push(s)
  b.chunks->Array.push("\n")
  b.termsOnLine = 0
}

let raw = (b: buffer, s: string) => b.chunks->Array.push(s)

let term = (b: buffer, text: string) => {
  if b.termsOnLine >= termsPerLine {
    b.chunks->Array.push("\n ")
    b.termsOnLine = 0
  }
  b.chunks->Array.push(text)
  b.termsOnLine = b.termsOnLine + 1
}

let endExpression = (b: buffer, tail: string) => {
  b.chunks->Array.push(tail)
  b.chunks->Array.push("\n")
  b.termsOnLine = 0
}

// Integer magnitude without exponent notation (coefficients reach ~1e10).
let magnitude = (v: float): string => Js.Float.toFixedWithPrecision(v, ~digits=0)

// " +1234 x7" / " -1234 x7". Zero coefficients are skipped by the caller.
let coefTerm = (coef: float, name: string): string => {
  let rounded = Js.Math.round(coef)
  (rounded < 0. ? " -" : " +") ++ magnitude(Js.Math.abs_float(rounded)) ++ " " ++ name
}

let xName = (i: int): string => "x" ++ i->Int.toString
let zName = (j: int): string => "z" ++ j->Int.toString
let sName = (k: int): string => "s" ++ k->Int.toString

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

// `benefits` is parallel to `players` and already carries the anti-back-to-back
// tier for any sat-out player who could not be hard-constrained: because z_j is
// binary, a tier-sized benefit is exactly a soft `z_j = 1`, with no extra
// variables.
let build = (
  ~candidates: array<candidate<'a>>,
  ~players: array<Player.t<'a>>,
  ~benefits: array<float>,
  ~fill: fillMode,
  ~mustPlayIds: array<string>,
  ~softRequiredIds: array<string>,
  ~requiredPenalty: float,
): lpModel<'a> => {
  // player id -> z index
  let playerIndex = Map.make()
  players->Array.forEachWithIndex((p, j) => playerIndex->Map.set(p.id, j))

  // player index -> candidate indices containing them
  let candidatesByPlayer: array<array<int>> = players->Array.map(_ => [])
  candidates->Array.forEachWithIndex((c, i) =>
    Match.players(c.match)->Array.forEach(p =>
      switch playerIndex->Map.get(p.id) {
      | None => () // not in the pool being solved for; ignore
      | Some(j) => (candidatesByPlayer->Array.getUnsafe(j))->Array.push(i)
      }
    )
  )

  let mustPlayPlayerIndices = mustPlayIds->Array.filterMap(id => playerIndex->Map.get(id))
  let softRequiredPlayerIndices = softRequiredIds->Array.filterMap(id => playerIndex->Map.get(id))

  // Only sound to shift the objective when the number of selected matches — and
  // therefore the number of playing players — is fixed.
  let (costOffset, benefitOffset) = switch fill {
  | AtMostFill(_, reward) => (reward, 0.)
  | ExactFill(_) => (
      candidates->Array.reduce(infinity, (acc, c) =>
        Js.Math.min_float(acc, c.cost +. c.surcharge)
      ),
      benefits->Array.reduce(infinity, (acc, b) => Js.Math.min_float(acc, b)),
    )
  }
  let costOffset = Float.isFinite(costOffset) ? costOffset : 0.
  let benefitOffset = Float.isFinite(benefitOffset) ? benefitOffset : 0.

  let b = makeBuffer()

  // --- objective -----------------------------------------------------------
  line(b, "Minimize")
  raw(b, " obj:")
  b.termsOnLine = 0
  candidates->Array.forEachWithIndex((c, i) =>
    term(b, coefTerm(c.cost +. c.surcharge -. costOffset, xName(i)))
  )
  benefits->Array.forEachWithIndex((benefit, j) =>
    if Js.Math.round(benefit -. benefitOffset) != 0. {
      term(b, coefTerm(-.(benefit -. benefitOffset), zName(j)))
    }
  )
  softRequiredPlayerIndices->Array.forEachWithIndex((_, k) =>
    term(b, coefTerm(requiredPenalty, sName(k)))
  )
  endExpression(b, "")

  // --- constraints ---------------------------------------------------------
  line(b, "Subject To")
  let numConstraints = ref(0)

  // Each player is in at most one selected match; z_j records whether they play.
  players->Array.forEachWithIndex((_, j) => {
    raw(b, " cp" ++ j->Int.toString ++ ":")
    b.termsOnLine = 0
    (candidatesByPlayer->Array.getUnsafe(j))->Array.forEach(i => term(b, " + " ++ xName(i)))
    term(b, " - " ++ zName(j))
    endExpression(b, " = 0")
    numConstraints := numConstraints.contents + 1
  })

  if candidates->Array.length > 0 {
    raw(b, " courts:")
    b.termsOnLine = 0
    candidates->Array.forEachWithIndex((_, i) => term(b, " + " ++ xName(i)))
    switch fill {
    | ExactFill(target) => endExpression(b, " = " ++ target->Int.toString)
    | AtMostFill(target, _) => endExpression(b, " <= " ++ target->Int.toString)
    }
    numConstraints := numConstraints.contents + 1
  }

  // Hard "this player plays". Used for required players, and for players who
  // sat out the previous round, whenever the seat count allows it.
  mustPlayPlayerIndices->Array.forEachWithIndex((j, k) => {
    line(b, " fix" ++ k->Int.toString ++ ": + " ++ zName(j) ++ " = 1")
    numConstraints := numConstraints.contents + 1
  })

  // Soft "this player must play": z_j + s_k >= 1.
  softRequiredPlayerIndices->Array.forEachWithIndex((j, k) => {
    line(b, " req" ++ k->Int.toString ++ ": + " ++ zName(j) ++ " + " ++ sName(k) ++ " >= 1")
    numConstraints := numConstraints.contents + 1
  })

  // --- variable declarations ----------------------------------------------
  line(b, "Binary")
  b.termsOnLine = 0
  candidates->Array.forEachWithIndex((_, i) => term(b, " " ++ xName(i)))
  players->Array.forEachWithIndex((_, j) => term(b, " " ++ zName(j)))
  softRequiredPlayerIndices->Array.forEachWithIndex((_, k) => term(b, " " ++ sName(k)))
  endExpression(b, "")

  line(b, "End")

  {
    lp: b.chunks->Array.join(""),
    candidates,
    players,
    softRequiredPlayerIndices,
    mustPlayPlayerIndices,
    fill,
    costOffset,
    benefitOffset,
    numVariables: candidates->Array.length +
    players->Array.length +
    softRequiredPlayerIndices->Array.length,
    numConstraints: numConstraints.contents,
  }
}

// ---------------------------------------------------------------------------
// Decoding
// ---------------------------------------------------------------------------

// Indices of the candidates HiGHS selected. Binary variables come back as
// floats, hence the 0.5 threshold.
let selectedCandidateIndices = (
  model: lpModel<'a>,
  columns: Js.Dict.t<HighsBindings.column>,
): array<int> =>
  model.candidates->Array.reduceWithIndex([], (acc, _, i) =>
    switch columns->Js.Dict.get(xName(i)) {
    | Some({primal}) if primal > 0.5 => acc->Array.concat([i])
    | _ => acc
    }
  )
