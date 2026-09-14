import { Writable } from "stream";

function asRelayDataAppend(relayData) {
  return `window.__RELAY_DATA.push(${JSON.stringify(relayData)})`;
}

export default class PreloadInsertingStreamNode extends Writable {
  constructor(writable) {
    super();
    this._queryData = [];
    this._assetLoaderTags = [];
    this._writable = writable;
  }

  /**
   * Should be invoked when a new Relay query is started or updated.
   *
   * @param {string} id
   *   The query ID used to track the request between server and client.
   * @param {*} response
   *   The Relay response or undefined in case this request is just being initiated.
   * @param {boolean|undefined} final
   *   Whether this is the final response for this query (or undefined in case the query is just being initiated).
   */
  onQuery(id, response, final) {
    this._queryData.push({ id, response, final })
  }

  /**
   * Should be invoked when a new asset has been used.
   *
   * @param {string} loaderTag
   *   The HTML tag (e.g. `link` or `script`) that loads the required resource.
   */
  onAssetPreload(loaderTag) {
    this._assetLoaderTags.push(loaderTag)
  }

  /**
   * Generates the HTML tags needed to load assets used since the last call.
   *
   * @returns {string}
   *   An HTML string containing Relay Data snippets and asset loading tags.
   */
  _generateNewScriptTagsSinceLastCall() {
    let scriptTags = '';

    if (this._queryData.length > 0) {
      console.log("[DEBUG]: Pushing tags to stream");
      scriptTags += `<script type="text/javascript" class="__relay_data">
          window.__RELAY_DATA = window.__RELAY_DATA || [];
          ${this._queryData.map(asRelayDataAppend).join("\n")}
          Array.prototype.forEach.call(
            document.getElementsByClassName("__relay_data"),
            function (element) {
              element.remove()
            }
          );
          </script>`;

      this._queryData = [];
      console.log(scriptTags);
    }

    if (this._assetLoaderTags.length > 0) {
      scriptTags += this._assetLoaderTags.join("");

      this._assetLoaderTags = [];
    }

    return scriptTags;
  }

  _write(chunk, encoding, callback) {
    // This should pick up any new tags that hasn't been previously
    // written to this stream.
      let scriptTags = this._generateNewScriptTagsSinceLastCall();
      if (scriptTags.length > 0) {
        // Write it before the HTML to ensure that we can start
        // downloading it as early as possible.
        this._writable.write(scriptTags);
      }
    // Finally write whatever React tried to write.
    //
    // The completion callback is invoked here rather than deferred to the
    // destination, because a compressed response gives us no reliable signal to
    // defer on. Two ways that bites, both of which hang the response forever:
    //
    //  - `compression` replaces res.write with a two-argument
    //    (chunk, encoding) function that silently drops a third argument, so
    //    handing it `callback` means this stream is never told the write
    //    finished and stops pulling from React after the first chunk.
    //  - Waiting for res to emit "drain" instead does not work either: that
    //    middleware writes into its own zlib stream, so when its write() returns
    //    false it is zlib that is backed up, not res, and res may never drain.
    //    The body arrives but "finish" never fires, so res.end() is never called.
    //
    // Acking immediately means this stream applies no backpressure upstream to
    // React. That is fine here: the destination buffers, and an SSR document is
    // bounded (a few hundred KB) rather than an open-ended stream.
    this._writable.write(chunk, encoding);
    callback();
  }

  flush() {
    if (typeof this._writable.flush === 'function') {
      this._writable.flush();
    }
  }
}
