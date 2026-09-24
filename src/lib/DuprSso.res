/** Reading the message DUPR's SSO iframe posts back to us.

 DUPR's own sample reads the tokens straight off the event object, but a real
 `MessageEvent` carries them under `data`, and some hosts post that payload
 as a JSON string. Both shapes are accepted.

 Only the two tokens are taken. The message also carries a DUPR id and a
 ratings blob, and neither is trustworthy: anything on the page could have
 posted them. The server asks DUPR who the token belongs to instead. */

type messageEvent
@get external origin: messageEvent => string = "origin"
@get external data: messageEvent => JSON.t = "data"

@val @scope("window")
external addMessageListener: (string, messageEvent => unit) => unit = "addEventListener"
@val @scope("window")
external removeMessageListener: (string, messageEvent => unit) => unit = "removeEventListener"

type url
@new external makeUrl: string => url = "URL"
@get external urlOrigin: url => string = "origin"

/** The origin to accept messages from, derived from the SSO URL the server
 gave us rather than hardcoded, so UAT and production need no branch here. */
let originOf = (ssoUrl: string): option<string> =>
  switch makeUrl(ssoUrl)->urlOrigin {
  | origin => Some(origin)
  | exception _ => None
  }

type tokens = {accessToken: string, refreshToken: string}

/** What DUPR's page can post to us, sorted by what the card should do.

 `Ignored` is traffic from somewhere other than DUPR — the page receives
 postMessage from other sources, so this is silently dropped.

 `Unrecognized` is from DUPR but not the login payload. DUPR's page posts
 other things to its parent (payment status, "started"/"aborted" events), and
 a message we do not understand is not a failure: the login may still be in
 progress, so the card keeps waiting. The keys are handed back for logging.

 `Rejected` is DUPR saying the login cannot complete — `{error: ...}` — for
 instance when the account still needs setup on DUPR's side. DUPR's own panel
 explains what to do, so the card must keep it visible. */
type parsed =
  | Ignored
  | Unrecognized(array<string>)
  | Rejected(string)
  | Tokens(tokens)

let nonEmptyString = (obj: Dict.t<JSON.t>, key: string): option<string> =>
  obj
  ->Dict.get(key)
  ->Option.flatMap(JSON.Decode.string)
  ->Option.flatMap(s => s->String.trim == "" ? None : Some(s))

let parseMessage = (~ssoOrigin: string, ~origin: string, ~data: JSON.t): parsed =>
  if origin != ssoOrigin {
    Ignored
  } else {
    /* Some embeds post the payload as a JSON string rather than an object. */
    let decoded = switch data->JSON.Decode.string {
    | Some(s) =>
      switch JSON.parseExn(s) {
      | json => Some(json)
      | exception _ => None
      }
    | None => Some(data)
    }
    switch decoded->Option.flatMap(JSON.Decode.object) {
    | None => Unrecognized([])
    | Some(obj) =>
      switch (
        nonEmptyString(obj, "userToken")->Option.orElse(nonEmptyString(obj, "accessToken")),
        nonEmptyString(obj, "refreshToken"),
        nonEmptyString(obj, "error"),
      ) {
      | (Some(accessToken), Some(refreshToken), _) => Tokens({accessToken, refreshToken})
      | (_, _, Some(reason)) => Rejected(reason)
      | _ => Unrecognized(obj->Dict.keysToArray)
      }
    }
  }
