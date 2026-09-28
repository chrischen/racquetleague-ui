// Node-side schema loading for the scenario middleware. `yarn start` rewrites
// data/schema.graphql from the backend before the server boots, and a peer may
// regenerate it later, so the schema is rebuilt whenever the file changes.
import { readFileSync, statSync } from "node:fs";
import { buildMockSchema } from "./engine.mjs";

export function createSchemaLoader(schemaPath) {
  let cached;
  return function getSchema() {
    const mtime = statSync(schemaPath).mtimeMs;
    if (!cached || cached.mtime !== mtime) {
      cached = { mtime, schema: buildMockSchema(readFileSync(schemaPath, "utf8")) };
    }
    return cached.schema;
  };
}
