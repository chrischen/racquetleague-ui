// The mock GraphQL engine behind dev scenarios (dev/scenarios/*.mjs) and the
// Storybook Relay decorator (.storybook/relay.tsx). It executes a real Relay
// operation against data/schema.graphql, so every selected field gets a
// value of the right shape; a scenario only states the fields it cares about.
//
// Browser-safe on purpose: it imports nothing but `graphql`, so Storybook can
// bundle it. Anything that touches the filesystem lives in mock-schema.mjs.
//
// Mock vocabulary, shared by scenarios and stories:
//
//   mocks: {
//     TypeName: { field: value | (source, args, info) => value },
//     TypeName: (source) => ({ field: ... }),  // called once per object
//   }
//
// Resolution order for each field: a value already on the parent object, then
// the parent type's mock (then its interfaces' mocks), then a default. See
// dev/scenarios/README.md for the defaults and the two rules about ids.
import {
  Kind,
  buildASTSchema,
  execute,
  getNamedType,
  getNullableType,
  isAbstractType,
  isEnumType,
  isListType,
  isNonNullType,
  isObjectType,
  parse,
  visit,
} from "graphql";

const INCREMENTAL = new Set(["defer", "stream"]);

// graphql 17 alpha.3 accepts the @defer/@stream definitions in the SDL, but
// earlier alphas threw on them. Dropping them keeps either behaviour working
// and guarantees execute() never takes the incremental path.
export function buildMockSchema(sdl) {
  const ast = parse(sdl);
  return buildASTSchema({
    ...ast,
    definitions: ast.definitions.filter(
      (d) => !(d.kind === Kind.DIRECTIVE_DEFINITION && INCREMENTAL.has(d.name.value)),
    ),
  });
}

// Relay accepts deferred fragments delivered inline in one final payload (it
// logs a dev warning), so the mock answers every operation with a single body.
export function stripIncrementalDirectives(document) {
  return visit(document, {
    Directive: (node) => (INCREMENTAL.has(node.name.value) ? null : undefined),
  });
}

export const FIXED_DATETIME = "2026-01-01T00:00:00.000Z";

// "viewer/events/edges/0/node" for the object that owns the field being
// resolved. Keys are response keys, so aliases and list indices are included.
function objectPath(info) {
  const keys = [];
  for (let p = info.path.prev; p; p = p.prev) keys.push(p.key);
  return keys.reverse().join("/");
}

function defaultScalar(type, info) {
  switch (type.name) {
    case "ID":
      // Distinct per object: Relay normalizes records by id, so two list
      // items sharing one would collapse into a single record.
      return `${info.parentType.name}:${objectPath(info)}`;
    case "String":
      return "";
    case "Int":
    case "Float":
      return 0;
    case "Boolean":
      return false;
    case "Datetime":
      return FIXED_DATETIME;
    default:
      return "";
  }
}

function defaultValue(returnType, info) {
  if (!isNonNullType(returnType)) {
    // Lists stay arrays even when nullable: connection handlers and every
    // Array.map in the components expect one.
    return isListType(returnType) ? [] : null;
  }
  const type = getNullableType(returnType);
  if (isListType(type)) return [];
  if (isEnumType(type)) return type.getValues()[0].name;
  if (isObjectType(type) || isAbstractType(type)) return {};
  return defaultScalar(type, info);
}

// The type mock for one parent object, computed at most once per object per
// operation. Function mocks see the object they are completing.
function typeMock(ctx, typeName, source) {
  const mock = ctx.mocks?.[typeName];
  if (mock == null) return undefined;
  if (typeof mock !== "function") return mock;
  let perType = ctx.memo.get(source);
  if (!perType) ctx.memo.set(source, (perType = new Map()));
  if (!perType.has(typeName)) perType.set(typeName, mock(source) ?? {});
  return perType.get(typeName);
}

function lookup(source, ctx, info) {
  const { fieldName, parentType } = info;
  if (source != null && typeof source === "object" && fieldName in source) {
    return { found: true, value: source[fieldName] };
  }
  if (source != null && typeof source === "object") {
    for (const name of [parentType.name, ...parentType.getInterfaces().map((i) => i.name)]) {
      const mockObj = typeMock(ctx, name, source);
      if (mockObj && fieldName in mockObj) return { found: true, value: mockObj[fieldName] };
    }
  }
  return { found: false };
}

const hasIdField = (type) => typeof type.getFields === "function" && "id" in type.getFields();

export function fieldResolver(source, args, ctx, info) {
  const hit = lookup(source, ctx, info);
  let value = hit.found ? hit.value : defaultValue(info.returnType, info);
  if (typeof value === "function") value = value(source, args, info);

  // `node(id:)`, `event(id:)`, `user(id:)`: the object answers to the id it
  // was asked for, unless the scenario gave it one explicitly.
  if (
    typeof args?.id === "string" &&
    value != null &&
    typeof value === "object" &&
    !Array.isArray(value) &&
    !("id" in value) &&
    hasIdField(getNamedType(info.returnType))
  ) {
    value = { id: args.id, ...value };
  }
  return value;
}

export function typeResolver(value, _ctx, info, abstractType) {
  const possible = info.schema.getPossibleTypes(abstractType).map((t) => t.name);
  if (value?.__typename && possible.includes(value.__typename)) return value.__typename;
  // Default ids are "<Type>:<path>", so a default object remembers its type.
  const prefix = typeof value?.id === "string" ? value.id.split(":")[0] : undefined;
  if (prefix && possible.includes(prefix)) return prefix;
  return possible[0];
}

// Executes one GraphQL request against the mock schema. `label` tags the
// console warning when the mocks produce errors, which almost always means a
// mock returned the wrong shape (a string where an object was selected, null
// on a non-null field).
export async function executeWithMocks(schema, mocks, request, { label = "mock" } = {}) {
  const document = stripIncrementalDirectives(
    typeof request.query === "string" ? parse(request.query) : request.query,
  );
  const result = await execute({
    schema,
    document,
    rootValue: {},
    contextValue: { mocks: mocks ?? {}, memo: new WeakMap() },
    variableValues: request.variables ?? {},
    operationName: request.operationName ?? undefined,
    fieldResolver,
    typeResolver,
  });
  if (result.errors?.length) {
    console.warn(
      `[${label}] ${result.errors.length} GraphQL error(s):`,
      result.errors.map((e) => `${e.message} at ${e.path?.join(".") ?? "?"}`),
    );
  }
  const out = { data: result.data ?? null };
  if (result.errors?.length) out.errors = result.errors.map((e) => e.toJSON?.() ?? { message: e.message });
  // graphql-js builds result objects with no prototype. Relay's normalizer
  // calls data.hasOwnProperty() on selections through unions and interfaces,
  // which throws on those. Over HTTP (the dev server) JSON makes them plain;
  // in-process callers (Storybook's Relay network) need the same here.
  return JSON.parse(JSON.stringify(out));
}

export function operationNameOf(request) {
  if (request.operationName) return request.operationName;
  const match = /\b(?:query|mutation|subscription)\s+([A-Za-z_][A-Za-z0-9_]*)/.exec(request.query ?? "");
  return match?.[1];
}

// Per-type merge of two mock sets; `override` wins field by field. Either side
// may be an object or a function of the source object.
export function mergeMocks(base = {}, override = {}) {
  const out = { ...base };
  for (const [typeName, mock] of Object.entries(override)) {
    const prev = out[typeName];
    if (prev == null) {
      out[typeName] = mock;
    } else if (typeof prev !== "function" && typeof mock !== "function") {
      out[typeName] = { ...prev, ...mock };
    } else {
      const call = (m, source) => (typeof m === "function" ? m(source) : m);
      out[typeName] = (source) => ({ ...call(prev, source), ...call(mock, source) });
    }
  }
  return out;
}

