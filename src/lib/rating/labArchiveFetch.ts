// Fetching for `SimLabArchive`. Kept in TypeScript because both halves are
// browser plumbing ReScript has no first-class binding for: Vite's
// `import.meta.env` and the streaming decompressor.

/** The app's base path. Vite rewrites this at build time; the fallback covers
 *  SSR and the Node-side generator, where `import.meta.env` is absent. */
export const assetBase = (): string => {
  try {
    return import.meta.env?.BASE_URL ?? "/";
  } catch {
    return "/";
  }
};

/**
 * Fetch a text asset, transparently gunzipping a `.gz` one.
 *
 * The saved runs are ~6 MB of JSON and ~10x smaller gzipped, which is the
 * difference between an asset worth committing and one that is not. They are
 * stored pre-compressed rather than left to the server, because the dev server
 * and the production one disagree about what they will compress on the fly and
 * a 6 MB uncompressed download on a phone is not acceptable either way.
 */
export async function fetchText(url: string): Promise<string> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${res.status} ${res.statusText} — ${url}`);
  if (!url.endsWith(".gz")) return res.text();

  const buf = await res.arrayBuffer();
  // Whether the bytes are still compressed is decided by looking at them, not
  // by the file extension. Some servers and CDNs serve a `.gz` file with
  // `Content-Encoding: gzip`, which makes the browser decompress it before we
  // ever see it — and gunzipping that again would fail. The two-byte gzip
  // magic number says which case this is.
  const bytes = new Uint8Array(buf);
  const stillCompressed = bytes[0] === 0x1f && bytes[1] === 0x8b;
  if (!stillCompressed) return new TextDecoder().decode(buf);

  if (typeof DecompressionStream === "undefined")
    throw new Error("This browser cannot read compressed saved runs (no DecompressionStream).");
  const body = new Response(buf).body;
  if (!body) throw new Error(`Could not read ${url}`);
  return new Response(body.pipeThrough(new DecompressionStream("gzip"))).text();
}
