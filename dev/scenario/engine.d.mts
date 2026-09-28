// Types for engine.mjs, for the TypeScript side (.storybook/relay.tsx).
import type { GraphQLResolveInfo, GraphQLSchema } from "graphql";

/** A field value, or a function computing it from the parent object and field arguments. */
export type MockField = unknown | ((source: any, args: Record<string, any>, info: GraphQLResolveInfo) => unknown);

/** Per-type mocks keyed by GraphQL type name. A function form runs once per object of that type. */
export type Mocks = Record<string, Record<string, MockField> | ((source: any) => Record<string, MockField>)>;

export type MockRequest = {
  query: string;
  variables?: Record<string, unknown> | null;
  operationName?: string | null;
};

export type MockResponse = {
  data: Record<string, unknown> | null;
  errors?: Array<{ message: string; [key: string]: unknown }>;
};

export const FIXED_DATETIME: string;
export function buildMockSchema(sdl: string): GraphQLSchema;
export function executeWithMocks(
  schema: GraphQLSchema,
  mocks: Mocks | undefined,
  request: MockRequest,
  options?: { label?: string },
): Promise<MockResponse>;
export function mergeMocks(base?: Mocks, override?: Mocks): Mocks;
export function operationNameOf(request: MockRequest): string | undefined;
