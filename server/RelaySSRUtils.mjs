// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as Js_json from "rescript/lib/es6/js_json.js";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as RescriptRelay from "rescript-relay/src/RescriptRelay.mjs";
import * as RelayRuntime from "relay-runtime";
import * as Client from "react-dom/client";
import * as RelayRouter__Bindings from "./RelayRouter__Bindings.mjs";

var streamedPreCache = {};

var replaySubjects = {};

function cleanupId(id) {
  console.log("[debug] Cleaning up id \"" + id + "\"");
  Js_dict.unsafeDeleteKey(replaySubjects, id);
}

function handleIncomingStreamedDataEntry(streamedEntry) {
  console.log("[debug] Got streamed entry: " + Belt_Option.getWithDefault(JSON.stringify(streamedEntry), "-"));
  var replaySubject = Js_dict.get(replaySubjects, streamedEntry.id);
  if (replaySubject !== undefined) {
    var replaySubject$1 = Caml_option.valFromOption(replaySubject);
    RelayRouter__Bindings.RelayReplaySubject.applyPayload(replaySubject$1, streamedEntry);
    if (Belt_Option.getWithDefault(streamedEntry.final, false)) {
      console.log("[debug] completing replay subject with id " + streamedEntry.id);
      replaySubject$1.complete();
      return ;
    } else {
      return ;
    }
  }
  replaySubjects[streamedEntry.id] = new RelayRuntime.ReplaySubject();
  var data = Js_dict.get(streamedPreCache, streamedEntry.id);
  if (data !== undefined) {
    data.push(streamedEntry);
  } else {
    streamedPreCache[streamedEntry.id] = [streamedEntry];
  }
}

function bootOnClient(target, render) {
  var boot = function () {
    Belt_Array.forEach(Belt_Option.getWithDefault(Caml_option.nullable_to_opt(window.__RELAY_DATA), []), (function (streamedEntry) {
            handleIncomingStreamedDataEntry(streamedEntry);
          }));
    window.__RELAY_DATA = {
      push: (function (streamedEntry) {
          console.log("[debug] Got stream response when client was ready: ", streamedEntry);
          handleIncomingStreamedDataEntry(streamedEntry);
        })
    };
    console.log("[debug] Booting because stream said so...");
    Client.hydrateRoot(target, render(undefined));
  };
  window.__BOOT = boot;
  if (Belt_Option.getWithDefault(Caml_option.nullable_to_opt(window.__READY_TO_BOOT), false)) {
    boot(undefined);
  }
  window.__STREAM_COMPLETE = (function () {
      console.log("[debug] completing stream: " + Object.keys(replaySubjects).join(", "));
      Belt_Array.forEach(Object.keys(replaySubjects), (function (key) {
              Js_dict.unsafeDeleteKey(replaySubjects, key);
            }));
    });
}

function subscribeToReplaySubject(replaySubject, sink) {
  return replaySubject.subscribe({
              next: (function (data) {
                  sink.next(data);
                }),
              error: (function (e) {
                  sink.error(e);
                }),
              complete: (function () {
                  sink.complete(undefined);
                })
            });
}

function applyPreCacheData(replaySubject, id) {
  var preCacheData = Js_dict.get(streamedPreCache, id);
  if (preCacheData !== undefined) {
    Belt_Array.forEach(preCacheData, (function (data) {
            var response = data.response;
            if (response === undefined) {
              return ;
            }
            var $$final = data.final;
            if ($$final !== undefined) {
              replaySubject.next(response);
              if ($$final) {
                replaySubject.complete();
                return cleanupId(id);
              } else {
                return ;
              }
            }
            
          }));
    return Js_dict.unsafeDeleteKey(streamedPreCache, id);
  }
  
}

function makeIdentifier(operation, variables) {
  return operation.name + Belt_Option.getWithDefault(JSON.stringify(variables), "{}");
}

function makeClientFetchFunction($$fetch) {
  return function (operation, variables, _cacheConfig, _uploads) {
    return RelayRuntime.Observable.create(function (sink) {
                var id = makeIdentifier(operation, variables);
                var replaySubject = Js_dict.get(replaySubjects, id);
                if (replaySubject !== undefined) {
                  var replaySubject$1 = Caml_option.valFromOption(replaySubject);
                  console.log("[debug] request " + id + " had ReplaySubject");
                  var subscription = subscribeToReplaySubject(replaySubject$1, sink);
                  var cleanupSubscription = replaySubject$1.subscribe({
                        complete: (function () {
                            cleanupId(id);
                          })
                      });
                  applyPreCacheData(replaySubject$1, id);
                  return {
                          unsubscribe: (function () {
                              subscription.unsubscribe(undefined);
                              cleanupSubscription.unsubscribe(undefined);
                            }),
                          closed: false
                        };
                }
                console.log("[debug] request " + id + " did not have ReplaySubject");
                return $$fetch(sink, operation, variables, _cacheConfig, _uploads);
              });
  };
}

function makeServerFetchFunction(onQuery, $$fetch) {
  return function (operation, variables, cacheConfig, uploads) {
    var queryId = makeIdentifier(operation, variables);
    onQuery(queryId, undefined, false);
    var observable = RelayRuntime.Observable.create(function (sink) {
          return $$fetch(sink, operation, variables, cacheConfig, uploads);
        });
    return observable.do({
                next: (function (payload) {
                    var obj = Js_json.decodeObject(payload);
                    var tmp;
                    if (obj !== undefined) {
                      var hasNext = Js_dict.get(obj, "hasNext");
                      if (hasNext !== undefined) {
                        var match = Js_json.decodeBoolean(hasNext);
                        tmp = match !== undefined && match ? false : true;
                      } else {
                        tmp = true;
                      }
                    } else {
                      tmp = true;
                    }
                    onQuery(queryId, Caml_option.some(payload), Caml_option.some(tmp));
                  })
              });
  };
}

export {
  bootOnClient ,
  makeIdentifier ,
  makeClientFetchFunction ,
  makeServerFetchFunction ,
}
/* RescriptRelay Not a pure module */
