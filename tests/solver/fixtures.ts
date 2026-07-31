// Shared fixtures for the solver tests.
//
// ReScript compiles records to plain objects and payload-free variants to
// strings, so building `Rating.Player.t` values from TypeScript is just object
// literals — no bindings needed.

export type Gender = "Male" | "Female";

export type Player = {
  data: undefined;
  id: string;
  intId: number;
  name: string;
  rating: { mu: number; sigma: number };
  ratingOrdinal: number;
  paid: boolean;
  gender: Gender;
  count: number;
};

export type Team = Player[];
export type Match = [Team, Team];

export type CompletedMatchEntity = {
  id: string;
  match: Match;
  score: [number, number] | undefined;
  createdAt: Date;
  synced: boolean;
};

export type Round = CompletedMatchEntity[];

const DEFAULT_MU = 25;
const DEFAULT_SIGMA = 25 / 3;

export function makePlayer(
  index: number,
  opts: Partial<{
    id: string;
    name: string;
    mu: number;
    sigma: number;
    gender: Gender;
    count: number;
  }> = {},
): Player {
  const mu = opts.mu ?? DEFAULT_MU;
  const sigma = opts.sigma ?? DEFAULT_SIGMA;
  return {
    data: undefined,
    id: opts.id ?? `p${index}`,
    intId: index,
    name: opts.name ?? `P${index}`,
    rating: { mu, sigma },
    ratingOrdinal: mu - 3 * sigma,
    paid: false,
    gender: opts.gender ?? "Male",
    count: opts.count ?? 0,
  };
}

// `n` players. `mu(i)` defaults to a flat pool; pass a function for skew.
export function makePool(
  n: number,
  mu?: (i: number) => number,
  gender?: (i: number) => Gender,
): Player[] {
  return Array.from({ length: n }, (_, i) =>
    makePlayer(i, { mu: mu?.(i), gender: gender?.(i) }),
  );
}

export function toRound(matches: Match[], roundIndex = 0): Round {
  return matches.map((match, i) => ({
    id: `r${roundIndex}m${i}`,
    match,
    score: undefined,
    createdAt: new Date(0),
    synced: false,
  }));
}

export const matchPlayers = (match: Match): Player[] => [...match[0], ...match[1]];

export const playerIds = (match: Match): string[] =>
  matchPlayers(match).map((p) => p.id);

export const teamKey = (team: Team): string =>
  team
    .map((p) => p.id)
    .sort()
    .join("-");

export const pairKey = (a: string, b: string): string => [a, b].sort().join("-");

// Bump every participant's play count, mirroring what the timeline replay does
// between rounds.
export function applyRound(players: Player[], round: Round): Player[] {
  const played = new Set(round.flatMap((m) => playerIds(m.match)));
  return players.map((p) =>
    played.has(p.id) ? { ...p, count: p.count + 1 } : p,
  );
}
