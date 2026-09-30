// Client for the dinkhunt analysis server (tools/graphql_server.py in the
// dinkhunt repo) — assumed to run on the same machine as the kiosk for now.
//
//   POST /clips     spools a muxed MP4 from the kiosk's rolling buffer and
//                   returns its repo-relative path (plus whether a court
//                   calibration sidecar was attached — see
//                   DINKHUNT_KIOSK_COURT on the server side).
//   POST /graphql   groundBounces(video) → the shot-finder's classified
//                   ground bounces, with times relative to the clip start
//                   (a spooled clip is a standalone video, so t maps
//                   directly onto the kiosk's buffer timeline).

let base = "http://localhost:3003"

type bounce = {
  i: int,
  t: float, // seconds from clip start
  frame: int,
  world: array<float>, // court metres, Z = 0
  pixel: array<float>, // image position in the clip's frame space
  footprint: array<array<float>>, // projected ground disc (perspective-correct marker), clip pixels
}

type response
@val external fetch: (string, 'init) => promise<response> = "fetch"
@get external ok: response => bool = "ok"
@get external status: response => int = "status"
@send external json: response => promise<Js.Json.t> = "json"
external unsafeFromJson: Js.Json.t => 'a = "%identity"

type clipUpload = {path: string, calibrated: bool}
type gqlError = {message: string}
type gqlEnvelope = {
  data: Js.Nullable.t<Dict.t<Js.Json.t>>,
  errors: Js.Nullable.t<array<gqlError>>,
}
type gqlData = {groundBounces: array<bounce>}
type gqlResponse = {data: Js.Nullable.t<gqlData>, errors: Js.Nullable.t<array<gqlError>>}

let uploadClip = async (blob: CaptureSession.blob): result<clipUpload, string> =>
  try {
    let response = await fetch(
      base ++ "/clips",
      {"method": "POST", "headers": {"Content-Type": "video/mp4"}, "body": blob},
    )
    if response->ok {
      Ok(unsafeFromJson(await response->json))
    } else {
      Error("clip upload failed (" ++ response->status->Int.toString ++ ")")
    }
  } catch {
  | _ => Error("dinkhunt server unreachable at " ++ base)
  }

let groundBounces = async (video: string): result<array<bounce>, string> =>
  try {
    let query = "query($v: String!) { groundBounces(video: $v) { i t frame world pixel footprint } }"
    let response = await fetch(
      base ++ "/graphql",
      {
        "method": "POST",
        "headers": {"Content-Type": "application/json"},
        "body": Js.Json.stringifyAny({"query": query, "variables": {"v": video}}),
      },
    )
    let payload: gqlResponse = unsafeFromJson(await response->json)
    switch payload.errors->Js.Nullable.toOption {
    | Some(errors) if errors->Array.length > 0 =>
      Error((errors->Array.getUnsafe(0)).message)
    | _ =>
      switch payload.data->Js.Nullable.toOption {
      | Some(data) => Ok(data.groundBounces)
      | None => Error("empty GraphQL response")
      }
    }
  } catch {
  | _ => Error("dinkhunt server unreachable at " ++ base)
  }

// ── Challenge analysis (bounces + the analyze.py-style overlay data) ─────────

type pathPoint = {t: float, x: float, y: float}
type challengeAnalysis = {
  width: int,
  height: int,
  fps: float,
  bounces: array<bounce>,
  paths: array<array<pathPoint>>, // per-shot ball paths, 30Hz, clip pixels
  // Every frame's real presentation time (s, frame 0 = 0) of the clip the server
  // analysed; with fps it maps analysis time (frame / fps) onto the video exactly
  // (FrameTimeline). Empty when the server could not read the timestamps.
  frameTimes: array<float>,
}
type challengeGqlData = {challenge: challengeAnalysis}
type challengeGqlResponse = {
  data: Js.Nullable.t<challengeGqlData>,
  errors: Js.Nullable.t<array<gqlError>>,
}

let challengeAnalysis = async (video: string): result<challengeAnalysis, string> =>
  try {
    let query = "query($v: String!) { challenge(video: $v) { width height fps bounces { i t frame world pixel footprint } paths { t x y } frameTimes } }"
    let response = await fetch(
      base ++ "/graphql",
      {
        "method": "POST",
        "headers": {"Content-Type": "application/json"},
        "body": Js.Json.stringifyAny({"query": query, "variables": {"v": video}}),
      },
    )
    let payload: challengeGqlResponse = unsafeFromJson(await response->json)
    switch payload.errors->Js.Nullable.toOption {
    | Some(errors) if errors->Array.length > 0 => Error((errors->Array.getUnsafe(0)).message)
    | _ =>
      switch payload.data->Js.Nullable.toOption {
      | Some(data) => Ok(data.challenge)
      | None => Error("empty GraphQL response")
      }
    }
  } catch {
  | _ => Error("dinkhunt server unreachable at " ++ base)
  }

// The kiosk's one-call flow: spool the buffer clip, then analyze it.
let challengeBounces = async (blob: CaptureSession.blob): result<
  (clipUpload, challengeAnalysis),
  string,
> =>
  switch await uploadClip(blob) {
  | Error(message) => Error(message)
  | Ok(upload) =>
    switch await challengeAnalysis(upload.path) {
    | Ok(analysis) => Ok((upload, analysis))
    | Error(message) => Error(message)
    }
  }


// ── Court calibration ────────────────────────────────────────────────────────

type courtCorner = {name: string, x: float, y: float}

// The solved camera (tools/graphql_server.KioskCamera), in the kiosk's own
// corner labelling, for reprojecting ANY court ground point onto the warped
// frame — see KioskCourtCalib.lensProject. Row-major 3x3s; `m` is
// world->camera and may be a reflection (the server folds a left/right
// relabel into it).
type kioskCamera = {
  k: array<float>, // pose intrinsics
  m: array<float>,
  t: array<float>,
  lensK: array<float>, // the lens model's intrinsics
  k1: float, // single radial term; 0 = no lens correction
  rmsPx: float, // anchor reprojection rms, raw pixels
}

type courtResult = {
  ok: bool,
  solved: bool,
  message: string,
  camera?: Js.Nullable.t<kioskCamera>, // absent/null when the solve failed
}

// Confirm asks only for the original fields so it keeps working against an
// analysis server that predates `camera` (the user restarts it on their own
// schedule); the preview asks for the camera.
let courtFields = "ok solved message"
let courtFieldsWithCamera = "ok solved message camera { k m t lensK k1 rmsPx }"

// POST one calibration request and pull `field` out of `data`.
let courtRequest = async (
  ~operation: string,
  ~field: string,
  ~fields: string,
  ~width: int,
  ~height: int,
  ~corners: array<courtCorner>,
): result<courtResult, string> =>
  try {
    let query =
      operation ++
      "($w: Int!, $h: Int!, $c: [CornerInput!]!) { " ++
      field ++
      "(width: $w, height: $h, corners: $c) { " ++
      fields ++ " } }"
    let response = await fetch(
      base ++ "/graphql",
      {
        "method": "POST",
        "headers": {"Content-Type": "application/json"},
        "body": Js.Json.stringifyAny({
          "query": query,
          "variables": {"w": width, "h": height, "c": corners},
        }),
      },
    )
    let payload: gqlEnvelope = unsafeFromJson(await response->json)
    switch payload.errors->Js.Nullable.toOption {
    | Some(errors) if errors->Array.length > 0 => Error((errors->Array.getUnsafe(0)).message)
    | _ =>
      switch payload.data->Js.Nullable.toOption->Option.flatMap(data => data->Dict.get(field)) {
      | Some(result) => Ok(unsafeFromJson(result))
      | None => Error("empty GraphQL response")
      }
    }
  } catch {
  | _ => Error("dinkhunt server unreachable at " ++ base)
  }

// Persist the kiosk camera's court corners on the analysis server (it writes
// the court pkl that gets attached to every spooled clip) and solve the pose
// immediately so bad drags fail loudly here, not hours later on a clip.
let setKioskCourt = (~width, ~height, ~corners) =>
  courtRequest(
    ~operation="mutation",
    ~field="setKioskCourt",
    ~fields=courtFields,
    ~width,
    ~height,
    ~corners,
  )

// The same solve WITHOUT saving: live feedback while the user drags (the
// kiosk reprojects the court through the returned lens-corrected camera).
let previewKioskCourt = (~width, ~height, ~corners) =>
  courtRequest(
    ~operation="query",
    ~field="previewKioskCourt",
    ~fields=courtFieldsWithCamera,
    ~width,
    ~height,
    ~corners,
  )


// ── Test mode (fixed clip, no camera needed) ─────────────────────────────────

let testClipName = "test_challenge.mov"

// Duration of a blob-backed video, probed off-DOM.
let urlDuration: string => promise<float> = %raw(`(url) => new Promise((resolve) => {
  const v = document.createElement('video');
  v.preload = 'metadata';
  v.onloadedmetadata = () => resolve(isFinite(v.duration) ? v.duration : 0);
  v.onerror = () => resolve(0);
  v.src = url;
})`)

@send external blob: response => promise<CaptureSession.blob> = "blob"

// The fixed test clip the analysis server holds at its repo root — used by
// the kiosk's test mode when no live camera/buffer exists. Analysis runs
// server-side against the SAME file by name, so nothing is uploaded.
let fetchTestClip = async (): result<CaptureSession.blob, string> =>
  try {
    let response = await fetch(base ++ "/testclip", {"method": "GET"})
    if response->ok {
      Ok(await response->blob)
    } else {
      Error("No test clip on the server — put test_challenge.mov in the dinkhunt repo root.")
    }
  } catch {
  | _ => Error("dinkhunt server unreachable at " ++ base)
  }

let testChallengeAnalysis = (): promise<result<challengeAnalysis, string>> =>
  challengeAnalysis(testClipName)


// ── Live analysis stream (auto-clip + instant Challenge) ────────────────────
//   POST /stream   one ring segment (whole GOPs, native frames) with the
//                  session id, its first frame's stream time and the court
//                  crop; the server replies with the rally heat and, when a
//                  heated rally has died down, the span to clip.

type clipSpan = {start: float, end: float}
type streamReply = {
  heat: float, // this window's reading, 0..1
  avg: float, // rolling heat
  threshold: float, // rolling heat that arms a clip
  phase: string, // "idle" | "hot"
  exchanges: int,
  speed: Js.Nullable.t<float>, // m/s
  clip: Js.Nullable.t<clipSpan>, // stream-clock seconds
  processing_s: float,
}
type streamError = {error: string}

let streamSegment = async (
  blob: CaptureSession.blob,
  ~session: string,
  ~t0: float,
  ~crop: option<ClipCrop.rect>,
): result<streamReply, string> =>
  try {
    let cropParam = switch crop {
    | Some(r) =>
      "&crop=" ++ [r.x, r.y, r.width, r.height]->Array.map(v => Int.toString(v))->Array.join(",")
    | None => ""
    }
    let response = await fetch(
      base ++ "/stream?session=" ++ session ++ "&t0=" ++ t0->Float.toString ++ cropParam,
      {"method": "POST", "headers": {"Content-Type": "video/mp4"}, "body": blob},
    )
    if response->ok {
      Ok(unsafeFromJson(await response->json))
    } else {
      let body: streamError = unsafeFromJson(await response->json)
      Error(body.error)
    }
  } catch {
  | _ => Error("dinkhunt server unreachable at " ++ base)
  }

type challengeStreamGqlData = {challengeStream: challengeAnalysis}
type challengeStreamGqlResponse = {
  data: Js.Nullable.t<challengeStreamGqlData>,
  errors: Js.Nullable.t<array<gqlError>>,
}

// A Challenge over [start, end] of the live stream (stream-clock seconds) —
// answered from detections already made, no upload or sweep. Result times are
// real seconds from ``start`` (frameTimes empty: identity timeline).
let challengeStreamAnalysis = async (~session: string, ~start: float, ~end_: float): result<
  challengeAnalysis,
  string,
> =>
  try {
    let query = "query($s: String!, $a: Float!, $b: Float!) { challengeStream(session: $s, start: $a, end: $b) { width height fps bounces { i t frame world pixel footprint } paths { t x y } frameTimes } }"
    let response = await fetch(
      base ++ "/graphql",
      {
        "method": "POST",
        "headers": {"Content-Type": "application/json"},
        "body": Js.Json.stringifyAny({"query": query, "variables": {"s": session, "a": start, "b": end_}}),
      },
    )
    let payload: challengeStreamGqlResponse = unsafeFromJson(await response->json)
    switch payload.errors->Js.Nullable.toOption {
    | Some(errors) if errors->Array.length > 0 => Error((errors->Array.getUnsafe(0)).message)
    | _ =>
      switch payload.data->Js.Nullable.toOption {
      | Some(data) => Ok(data.challengeStream)
      | None => Error("empty GraphQL response")
      }
    }
  } catch {
  | _ => Error("dinkhunt server unreachable at " ++ base)
  }

