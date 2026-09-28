// Finds and loads dev/scenarios/<name>.mjs. Files starting with "_" are
// helpers, not scenarios.
//
// Hot reload: each load imports the file with its mtime as a query string, so
// an edited scenario is picked up on the next request without a restart. Node
// caches whatever the scenario itself imports (such as _shared.mjs) as usual,
// so edits to those still need a server restart.
import { readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const NAME = /^[a-z0-9][a-z0-9_-]*$/i;

export function createRegistry(scenariosDir) {
  const cache = new Map();

  async function load(name) {
    if (!NAME.test(name)) return undefined;
    const file = join(scenariosDir, `${name}.mjs`);
    let mtime;
    try {
      mtime = statSync(file).mtimeMs;
    } catch {
      return undefined;
    }
    const hit = cache.get(name);
    if (hit && hit.mtime === mtime) return hit.scenario;
    const mod = await import(`${pathToFileURL(file).href}?v=${mtime}`);
    const scenario = { mode: "mock", mocks: {}, ...mod.default, name };
    cache.set(name, { mtime, scenario });
    return scenario;
  }

  async function list() {
    const names = readdirSync(scenariosDir)
      .filter((f) => f.endsWith(".mjs") && !f.startsWith("_"))
      .map((f) => f.slice(0, -".mjs".length))
      .filter((n) => NAME.test(n))
      .sort();
    return Promise.all(names.map(load));
  }

  return { load, list };
}
