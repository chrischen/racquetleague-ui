// Types for _shared.mjs, for stories and other TypeScript callers.
export { mergeMocks, FIXED_DATETIME } from "../scenario/engine.mjs";

export const emptyConnection: {
  edges: never[];
  pageInfo: { hasNextPage: false; hasPreviousPage: false; startCursor: null; endCursor: null };
};

/** Change every object in `data` whose `id` is `id`, touching only fields already present. */
export function patchRecords<T>(data: T, id: string | null | undefined, changes: Record<string, unknown>): T;

/** A signed-in viewer whose session user and profile share one User id. Extra fields override the defaults. */
export function signedInViewer(options?: { userId?: string } & Record<string, unknown>): Record<string, unknown>;
