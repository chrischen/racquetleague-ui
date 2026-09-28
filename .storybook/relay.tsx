/// <reference types="vite/client" />
// Relay for stories, fed by the same mock engine and mock vocabulary as the
// dev-server scenarios (dev/scenarios/README.md), so data written once serves
// both a whole page in the dev server and one component here.
//
// A story opts in with `parameters.relay`:
//
//   parameters: {
//     relay: {
//       query: node,               // ConcreteRequest from src/__generated__/<Name>_graphql.re.mjs
//       variables: {},             // optional
//       scenario: "new-user",      // optional: start from dev/scenarios/new-user.mjs
//       mocks: { User: { ... } },  // optional: merged over the scenario, field by field
//     },
//   }
//
// The loader executes the query before the story renders and the decorator
// commits the result into a fresh store, so the component reads its data
// synchronously: no fetch, no Suspense flash, nothing for a play function to
// wait on. Anything the story fetches later (a refetch, a mutation) is
// answered by the same mocks through the environment's network.
import * as React from "react";
import type { Decorator, Loader } from "@storybook/react-vite";
import { RelayEnvironmentProvider } from "react-relay";
import {
  Environment,
  Network,
  RecordSource,
  Store,
  createOperationDescriptor,
  getRequest,
  type ConcreteRequest,
  type GraphQLResponse,
  type Variables,
} from "relay-runtime";
import sdl from "../data/schema.graphql?raw";
import { buildMockSchema, executeWithMocks, mergeMocks, type Mocks, type MockResponse } from "../dev/scenario/engine.mjs";

export type RelayParameters = {
  query?: ConcreteRequest;
  variables?: Variables;
  scenario?: string;
  mocks?: Mocks;
};

type Loaded = {
  label: string;
  mocks: Mocks;
  request?: ConcreteRequest;
  variables: Variables;
  payload?: MockResponse;
};

const scenarios = import.meta.glob<{ default: { mocks?: Mocks } }>([
  "../dev/scenarios/*.mjs",
  "!../dev/scenarios/_*.mjs",
]);

let schema: ReturnType<typeof buildMockSchema> | undefined;
const getSchema = () => (schema ??= buildMockSchema(sdl));

async function mocksFor(params: RelayParameters): Promise<Mocks> {
  if (!params.scenario) return params.mocks ?? {};
  const load = scenarios[`../dev/scenarios/${params.scenario}.mjs`];
  if (!load) throw new Error(`parameters.relay.scenario: no dev/scenarios/${params.scenario}.mjs`);
  return mergeMocks((await load()).default.mocks ?? {}, params.mocks ?? {});
}

export const relayLoader: Loader = async ({ parameters, id }) => {
  const params: RelayParameters = parameters.relay ?? {};
  const label = `story:${id}`;
  const mocks = await mocksFor(params);
  const variables = params.variables ?? {};
  if (!params.query) return { relay: { label, mocks, variables } satisfies Loaded };
  const request = getRequest(params.query);
  const payload = await executeWithMocks(getSchema(), mocks, { query: request.params.text ?? "", variables }, { label });
  return { relay: { label, mocks, request, variables, payload } satisfies Loaded };
};

function makeEnvironment(loaded: Loaded | undefined): Environment {
  const mocks = loaded?.mocks ?? {};
  const label = loaded?.label ?? "story";
  const environment = new Environment({
    network: Network.create(
      (params, variables) =>
        executeWithMocks(getSchema(), mocks, { query: params.text ?? "", variables }, { label }) as Promise<GraphQLResponse>,
    ),
    store: new Store(new RecordSource()),
  });
  if (loaded?.request && loaded.payload?.data) {
    const operation = createOperationDescriptor(loaded.request, loaded.variables);
    // Retained for the environment's lifetime so garbage collection never
    // drops the records before the story's own query retains them.
    environment.retain(operation);
    environment.commitPayload(operation, loaded.payload.data);
  }
  return environment;
}

function RelayStoryProvider({ loaded, children }: { loaded: Loaded | undefined; children: React.ReactNode }) {
  const environment = React.useMemo(() => makeEnvironment(loaded), [loaded]);
  return (
    <RelayEnvironmentProvider environment={environment}>
      <React.Suspense fallback={null}>{children}</React.Suspense>
    </RelayEnvironmentProvider>
  );
}

export const withRelay: Decorator = (Story, context) => (
  <RelayStoryProvider loaded={context.loaded?.relay as Loaded | undefined}>
    <Story />
  </RelayStoryProvider>
);
