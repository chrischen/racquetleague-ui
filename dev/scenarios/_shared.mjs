// Helpers for scenario files. Not a scenario itself (leading underscore).
// Editing this file needs a dev server restart; editing a scenario does not.
export { mergeMocks, FIXED_DATETIME } from "../scenario/engine.mjs";

// The engine already defaults a non-null connection to this shape; spelling it
// out keeps a scenario readable when the emptiness is the point.
export const emptyConnection = {
  edges: [],
  pageInfo: { hasNextPage: false, hasPreviousPage: false, startCursor: null, endCursor: null },
};

// Overlay helper: change every object in a response whose `id` is `id`,
// wherever it sits. The app stores one record per id, so patching a single
// path (say viewer.profile) loses to any other copy of the same user in the
// response or in a later one. Only fields the query selected are touched; a
// change may be a function of the old value.
//
//   patch: (op, data, vars, { viewerId }) =>
//     patchRecords(data, viewerId, { email: null, lineUsername: "" })
export function patchRecords(data, id, changes) {
  if (id == null) return data;
  const visit = (node) => {
    if (Array.isArray(node)) {
      node.forEach(visit);
    } else if (node !== null && typeof node === "object") {
      if (node.id === id) {
        for (const [field, change] of Object.entries(changes)) {
          if (field in node) node[field] = typeof change === "function" ? change(node[field]) : change;
        }
      }
      Object.values(node).forEach(visit);
    }
  };
  visit(data);
  return data;
}

// A signed-in viewer whose session user and profile are the same User record.
// Relay stores both under one id, so they must agree: if they differ, fields
// selected under one overwrite the other.
export function signedInViewer({ userId = "user-1", ...viewer } = {}) {
  return {
    user: { id: userId },
    profile: { id: userId },
    viewerMetadata: { id: `viewer-metadata-${userId}`, unreadInboxCount: 0 },
    savedCard: null,
    inbox: null,
    subscriptions: [],
    events: emptyConnection,
    adminClubs: emptyConnection,
    clubs: emptyConnection,
    eventsForwardingAddress: "",
    eventsInboxAddress: null,
    ...viewer,
  };
}
