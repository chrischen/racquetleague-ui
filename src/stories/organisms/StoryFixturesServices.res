// Shared fixtures for the stories of organisms tied to hardware or outside
// services (Kiosk, KioskCourtCalib, AutocompleteLocation, ...); the app never
// imports this. Nothing here opens a real camera, reaches a network or calls a
// real API:
//
// - a synthetic court camera: a pickleball court drawn on a canvas in
//   perspective with a rally being played, exposed as a MediaStream
//   (canvas.captureStream), plus an encoder that renders the same rally into
//   a short video file;
// - a stand-in for navigator.mediaDevices that hands out that stream;
// - a stand-in for the dinkhunt analysis sidecar (the kiosk's localhost:3003
//   server) that answers the kiosk's fetches with fixture data, so a story
//   can never reach (or reconfigure) a real sidecar;
// - a stand-in for the Google Places SDK (window.google.maps.places plus the
//   @vis.gl APIProvider context), answering venue searches from a fixed list.
//
// Everything installed on window/navigator is restored when the story that
// installed it unmounts (`useInstalled`).

// ── Installing and restoring stand-ins ───────────────────────────────────────

/** Runs `install` once, before the story's children mount (so it is in place
 for their first effects), and the restore function it returns on unmount. */
let useInstalled = (install: unit => unit => unit) => {
  let (restore, _) = React.useState(() => install())
  React.useEffect0(() => Some(restore))
}

@val @scope("localStorage") external setStoredItem: (string, string) => unit = "setItem"
@val @scope("localStorage") external removeStoredItem: string => unit = "removeItem"

/** Sets or clears one localStorage key; the kiosk keeps its settings there. */
let setStored = (key, value: option<string>) =>
  switch value {
  | Some(value) => setStoredItem(key, value)
  | None => removeStoredItem(key)
  }

// ── The court scene ──────────────────────────────────────────────────────────
// World coordinates are KioskCourtCalib's: metres on the ground plane, the
// net along y = 0, +y toward the near (camera) side.

let hw = KioskCourtCalib.halfWid
let hl = KioskCourtCalib.halfLen
let kd = KioskCourtCalib.kitchenDepth

/** The kiosk asks the camera for 1080p; the synthetic camera delivers it. */
let frameWidth = 1920
let frameHeight = 1080

/** A camera as four ground-plane correspondences (world m -> 1080p px). */
type camera = array<((float, float), (float, float))>

/** Mounted high behind the near baseline: the whole court in frame. */
let baselineCamera: camera = [
  ((-.hw, hl), (380., 1010.)),
  ((hw, hl), (1540., 1010.)),
  ((hw, -.hl), (1185., 318.)),
  ((-.hw, -.hl), (735., 318.)),
]

/** Low and close, inside the near court: the near baseline is behind the
 camera, so only the kitchen and the far court are in frame. */
let closeCamera: camera = [
  ((-.hw, kd), (200., 1000.)),
  ((hw, kd), (1720., 1000.)),
  ((hw, -.kd), (1160., 330.)),
  ((-.hw, -.kd), (760., 330.)),
]

type scene = {width: int, height: int, h: array<float>}

let makeScene = (~camera: camera, ~width=frameWidth, ~height=frameHeight) => {
  let k = width->Int.toFloat /. frameWidth->Int.toFloat
  let pairs = camera->Array.map(((world, (x, y))) => (world, (x *. k, y *. k)))
  {width, height, h: KioskCourtCalib.solveHomography(pairs)->Option.getExn}
}

let project = (scene, (x, y)) => KioskCourtCalib.projectVisible(scene.h, (x, y))

// Pixels per metre across the frame at a ground point: sizes things that
// stand on the court (players, the net, the ball) at that depth.
let localScale = (scene, (x, y)) =>
  switch (project(scene, (x -. 0.5, y)), project(scene, (x +. 0.5, y))) {
  | (Some((ax, ay)), Some((bx, by))) => Math.sqrt((bx -. ax) ** 2. +. (by -. ay) ** 2.)
  | _ => 0.
  }

// Height reads a little shorter than width from a raised camera.
let uprightFactor = 0.85

type polygon = {fill: string, points: array<(float, float)>}

// A ground rectangle as thin strips along y, so the part of it behind the
// camera simply drops out.
let groundRect = (scene, ~fill, ~x0, ~x1, ~y0, ~y1) => {
  let steps = Math.Int.max(1, Math.ceil((y1 -. y0) /. 0.25)->Float.toInt)
  let at = i => y0 +. (y1 -. y0) *. Int.toFloat(i) /. Int.toFloat(steps)
  Array.fromInitializer(~length=steps, i => {
    let a = at(i)
    let b = at(i + 1)
    switch (
      project(scene, (x0, a)),
      project(scene, (x1, a)),
      project(scene, (x1, b)),
      project(scene, (x0, b)),
    ) {
    | (Some(p1), Some(p2), Some(p3), Some(p4)) => Some({fill, points: [p1, p2, p3, p4]})
    | _ => None
    }
  })->Array.filterMap(p => p)
}

// Something standing on the court: a box from `bottom` to `top` metres up,
// `width` metres wide, centred on a ground point.
let upright = (scene, ~fill, ~at, ~width, ~bottom, ~top) =>
  switch project(scene, at) {
  | None => []
  | Some((gx, gy)) => {
      let s = localScale(scene, at) *. uprightFactor
      let half = width *. localScale(scene, at) /. 2.
      [
        {
          fill,
          points: [
            (gx -. half, gy -. bottom *. s),
            (gx +. half, gy -. bottom *. s),
            (gx +. half, gy -. top *. s),
            (gx -. half, gy -. top *. s),
          ],
        },
      ]
    }
  }

type player = {at: (float, float), shirt: string, shorts: string}

let players = [
  {at: (1.5, 7.3), shirt: "#f97316", shorts: "#1f2937"},
  {at: (-1.4, 4.4), shirt: "#e11d48", shorts: "#111827"},
  {at: (-1.7, -3.6), shirt: "#facc15", shorts: "#1e3a8a"},
  {at: (1.3, -2.9), shirt: "#22d3ee", shorts: "#1e293b"},
]

let drawPlayer = (scene, player) =>
  [
    upright(scene, ~fill="#0b1220", ~at=player.at, ~width=0.34, ~bottom=0., ~top=0.12),
    upright(scene, ~fill=player.shorts, ~at=player.at, ~width=0.34, ~bottom=0.1, ~top=0.9),
    upright(scene, ~fill=player.shirt, ~at=player.at, ~width=0.46, ~bottom=0.85, ~top=1.48),
    upright(scene, ~fill="#e8b48a", ~at=player.at, ~width=0.22, ~bottom=1.48, ~top=1.72),
  ]->Array.flat

let lineWidth = 0.05
let lineRect = (scene, ~x0, ~x1, ~y0, ~y1) =>
  groundRect(
    scene,
    ~fill="#f8fafc",
    ~x0=x0 -. lineWidth /. 2.,
    ~x1=x1 +. lineWidth /. 2.,
    ~y0=y0 -. lineWidth /. 2.,
    ~y1=y1 +. lineWidth /. 2.,
  )

// The net: a sagging mesh between two posts, drawn upright over the net line.
let net = scene => {
  let post = hw +. 0.3
  let xs = Array.fromInitializer(~length=13, i => -.post +. 2. *. post *. Int.toFloat(i) /. 12.)
  let heightAt = x => 0.864 +. 0.05 *. (x /. post) ** 2.
  let lift = (x, h) =>
    switch project(scene, (x, 0.)) {
    | Some((gx, gy)) => Some((gx, gy -. h *. localScale(scene, (x, 0.)) *. uprightFactor))
    | None => None
    }
  let tops = xs->Array.filterMap(x => lift(x, heightAt(x)))
  let bands = xs->Array.filterMap(x => lift(x, heightAt(x) -. 0.06))
  let grounds = xs->Array.filterMap(x => lift(x, 0.))
  if tops->Array.length < 13 {
    []
  } else {
    Array.flat([
      [{fill: "rgba(15, 23, 42, 0.55)", points: tops->Array.concat(grounds->Array.toReversed)}],
      [{fill: "#f1f5f9", points: tops->Array.concat(bands->Array.toReversed)}],
      upright(scene, ~fill="#111827", ~at=(-.post, 0.), ~width=0.07, ~bottom=0., ~top=0.95),
      upright(scene, ~fill="#111827", ~at=(post, 0.), ~width=0.07, ~bottom=0., ~top=0.95),
    ])
  }
}

/** Everything that does not move, in paint order. */
let backdrop = scene => {
  let (near, far) = players->Array.reduce(([], []), ((near, far), p) => {
    let (_, y) = p.at
    y > 0. ? (near->Array.concat([p]), far) : (near, far->Array.concat([p]))
  })
  Array.flat([
    groundRect(scene, ~fill="#2f6f55", ~x0=-6.5, ~x1=6.5, ~y0=-12., ~y1=12.),
    groundRect(scene, ~fill="#2c5d8f", ~x0=-.hw, ~x1=hw, ~y0=-.hl, ~y1=hl),
    groundRect(scene, ~fill="#3b73a8", ~x0=-.hw, ~x1=hw, ~y0=-.kd, ~y1=kd),
    lineRect(scene, ~x0=-.hw, ~x1=hw, ~y0=hl, ~y1=hl),
    lineRect(scene, ~x0=-.hw, ~x1=hw, ~y0=-.hl, ~y1=-.hl),
    lineRect(scene, ~x0=-.hw, ~x1=-.hw, ~y0=-.hl, ~y1=hl),
    lineRect(scene, ~x0=hw, ~x1=hw, ~y0=-.hl, ~y1=hl),
    lineRect(scene, ~x0=-.hw, ~x1=hw, ~y0=kd, ~y1=kd),
    lineRect(scene, ~x0=-.hw, ~x1=hw, ~y0=-.kd, ~y1=-.kd),
    lineRect(scene, ~x0=0., ~x1=0., ~y0=kd, ~y1=hl),
    lineRect(scene, ~x0=0., ~x1=0., ~y0=-.hl, ~y1=-.kd),
    far->Array.flatMap(p => drawPlayer(scene, p)),
    net(scene),
    near->Array.flatMap(p => drawPlayer(scene, p)),
  ])
}

// ── The rally ────────────────────────────────────────────────────────────────
// Alternating contacts and bounces; the ball flies between consecutive points
// on a parabola (`arc` is the extra height at mid-flight).

type waypoint = {t: float, x: float, y: float, z: float, arc: float}

let rally = [
  {t: 0.0, x: 1.4, y: 7.1, z: 0.6, arc: 1.6}, // serve
  {t: 1.05, x: -1.5, y: -4.7, z: 0., arc: 0.5},
  {t: 1.4, x: -1.6, y: -5.9, z: 0.45, arc: 1.9}, // return, deep
  {t: 2.5, x: -0.8, y: 5.1, z: 0., arc: 0.45},
  {t: 2.85, x: -1.3, y: 5.6, z: 0.4, arc: 1.7}, // third-shot drop
  {t: 4.0, x: 0.5, y: -1.3, z: 0., arc: 0.35},
  {t: 4.3, x: 1.2, y: -2.6, z: 0.3, arc: 1.05}, // dink
  {t: 5.2, x: -0.7, y: 1.1, z: 0., arc: 0.35},
  {t: 5.5, x: -1.2, y: 2.6, z: 0.3, arc: 1.05}, // cross-court dink
  {t: 6.4, x: -1.9, y: -0.9, z: 0., arc: 0.35},
  {t: 6.7, x: -2.0, y: -2.5, z: 0.35, arc: 0.8}, // speed-up
  {t: 7.25, x: 2.2, y: 5.6, z: 0., arc: 0.4}, // winner
  {t: 7.9, x: 2.9, y: 7.8, z: 0., arc: 0.},
]

/** One rally, then a pause before the next serve. */
let rallyPeriod = 9.0

/** The ball at rally time `t`, in world metres (x, y, height). */
let ballAt = (t: float): option<(float, float, float)> => {
  let t = mod_float(t, rallyPeriod)
  let rec find = i =>
    switch (rally->Array.get(i), rally->Array.get(i + 1)) {
    | (Some(a), Some(b)) if t >= a.t && t <= b.t => {
        let s = (t -. a.t) /. (b.t -. a.t)
        Some((
          a.x +. (b.x -. a.x) *. s,
          a.y +. (b.y -. a.y) *. s,
          a.z +. (b.z -. a.z) *. s +. a.arc *. 4. *. s *. (1. -. s),
        ))
      }
    | (Some(_), Some(_)) => find(i + 1)
    | _ => None
    }
  find(0)
}

type ballSprite = {x: float, y: float, r: float, shadowX: float, shadowY: float}

let ballSprite = (scene, t): option<ballSprite> =>
  ballAt(t)->Option.flatMap(((x, y, z)) =>
    project(scene, (x, y))->Option.map(((gx, gy)) => {
      let s = localScale(scene, (x, y))
      {
        x: gx,
        y: gy -. z *. s *. uprightFactor,
        r: Math.max(2.5, 0.05 *. s),
        shadowX: gx,
        shadowY: gy,
      }
    })
  )

// ── Painting ─────────────────────────────────────────────────────────────────

type canvas
type renderer = {canvas: canvas, paint: float => unit}

let makeRenderer: (int, int, array<polygon>, float => option<ballSprite>) => renderer = %raw(`
  function (width, height, polygons, ball) {
    const background = document.createElement("canvas");
    background.width = width;
    background.height = height;
    const g = background.getContext("2d");
    // An indoor hall: dark wall above, the floor below.
    const wall = g.createLinearGradient(0, 0, 0, height);
    wall.addColorStop(0, "#1c252e");
    wall.addColorStop(0.28, "#33424d");
    wall.addColorStop(0.3, "#22302a");
    wall.addColorStop(1, "#2a3b33");
    g.fillStyle = wall;
    g.fillRect(0, 0, width, height);
    for (const polygon of polygons) {
      g.beginPath();
      polygon.points.forEach(([x, y], i) => (i === 0 ? g.moveTo(x, y) : g.lineTo(x, y)));
      g.closePath();
      g.fillStyle = polygon.fill;
      g.strokeStyle = polygon.fill;
      g.lineWidth = 1;
      g.fill();
      g.stroke();
    }
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    const paint = (t) => {
      ctx.drawImage(background, 0, 0);
      const b = ball(t);
      if (b !== undefined) {
        ctx.fillStyle = "rgba(0, 0, 0, 0.35)";
        ctx.beginPath();
        ctx.ellipse(b.shadowX, b.shadowY, b.r * 1.3, b.r * 0.55, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = "#e8ff5a";
        ctx.beginPath();
        ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2);
        ctx.fill();
      }
    };
    paint(0);
    return { canvas, paint };
  }
`)

// A live MediaStream of the renderer, repainted ~30 times a second until its
// track is stopped (the kiosk stops tracks when it drops a stream).
let liveStream: renderer => UserMedia.t = %raw(`
  function (renderer) {
    const stream = renderer.canvas.captureStream(30);
    const track = stream.getVideoTracks()[0];
    const start = performance.now();
    const timer = setInterval(() => {
      if (track.readyState === "ended") return clearInterval(timer);
      renderer.paint((performance.now() - start) / 1000);
    }, 1000 / 30);
    return stream;
  }
`)

let sceneFor = (camera: camera) => {
  let scene = makeScene(~camera)
  (scene, makeRenderer(scene.width, scene.height, backdrop(scene), t => ballSprite(scene, t)))
}

/** A fresh synthetic 1080p camera stream looking at the court. */
let courtStream = (~camera=baselineCamera) => {
  let (_, renderer) = sceneFor(camera)
  liveStream(renderer)
}

@send external stopTrack: UserMedia.track => unit = "stop"
let stopStream = (stream: UserMedia.t) => stream->UserMedia.getTracks->Array.forEach(stopTrack)

// ── Court calibration fixtures ───────────────────────────────────────────────

/** Where a camera sees a court landmark, nudged by `jitter` px as a hand
 would place it. */
let landmark = (scene, name, (jx, jy)) =>
  project(scene, KioskCourtCalib.worldOf(name))->Option.map(((x, y)): KioskCourtCalib.placedAnchor => {
    name,
    x: x +. jx,
    y: y +. jy,
  })

/** The anchors KioskCourtCalib stores once a court is confirmed, as JSON for
 localStorage (they only load on the frame size they were placed on). */
let storedAnchors = (~camera: camera, names: array<(string, (float, float))>) => {
  let scene = makeScene(~camera)
  let placed = names->Array.filterMap(((name, jitter)) => landmark(scene, name, jitter))
  JSON.stringifyAny({"width": frameWidth, "height": frameHeight, "placed": placed})
}

/** A whole court anchored from behind the baseline: six points, hand-placed. */
let anchoredCourt = () =>
  storedAnchors(
    ~camera=baselineCamera,
    [
      ("near_baseline_left", (1.5, -0.8)),
      ("near_baseline_right", (-1.2, 1.1)),
      ("far_baseline_left", (0.6, 0.9)),
      ("far_baseline_right", (-0.9, -0.4)),
      ("near_kitchen_centre", (0.8, 0.3)),
      ("net_right", (-0.5, 1.2)),
    ],
  )

/** Only the four kitchen corners from a close camera: the fit throws the near
 baseline behind the camera, which KioskCourtCalib flags as unstable. */
let kitchenOnly = () =>
  storedAnchors(
    ~camera=closeCamera,
    [
      ("near_kitchen_left", (1.2, -0.6)),
      ("near_kitchen_right", (-0.8, 0.9)),
      ("far_kitchen_left", (0.5, 0.4)),
      ("far_kitchen_right", (-0.6, -0.7)),
    ],
  )

// ── A stand-in for navigator.mediaDevices ────────────────────────────────────

@genType
type cameraAccess = [#granted | #denied | #absent]

type deviceInfo = {deviceId: string, kind: string, label: string, groupId: string}

let kioskCameras = [
  {deviceId: "cam-brio", kind: "videoinput", label: "Logitech BRIO (046d:085e)", groupId: "g-brio"},
  {
    deviceId: "cam-obsbot",
    kind: "videoinput",
    label: "OBSBOT Tail Air (3564:fef8)",
    groupId: "g-obsbot",
  },
  {
    deviceId: "mic-brio",
    kind: "audioinput",
    label: "Microphone (Logitech BRIO)",
    groupId: "g-brio",
  },
]

// Before permission is granted, browsers list cameras with blank labels.
let unlabeledCameras = [{deviceId: "", kind: "videoinput", label: "", groupId: ""}]

let installMediaDevices: (
  cameraAccess,
  array<deviceInfo>,
  unit => UserMedia.t,
) => unit => unit = %raw(`
  function (access, devices, openStream) {
    const media = navigator.mediaDevices;
    if (!media) return () => {};
    const define = (name, value) =>
      Object.defineProperty(media, name, { configurable: true, writable: true, value });
    define("enumerateDevices", async () => devices);
    define("getUserMedia", async () => {
      if (access === "granted") return openStream();
      throw access === "denied"
        ? new DOMException("Permission denied", "NotAllowedError")
        : new DOMException("Requested device not found", "NotFoundError");
    });
    return () => {
      delete media.enumerateDevices;
      delete media.getUserMedia;
    };
  }
`)

/** Camera access as the kiosk sees it: granted (the synthetic court camera
 and two named USB cameras), denied, or no camera at all. */
let useCameraAccess = (access: cameraAccess) =>
  useInstalled(() =>
    installMediaDevices(
      access,
      switch access {
      | #granted => kioskCameras
      | #denied => unlabeledCameras
      | #absent => []
      },
      () => courtStream(),
    )
  )

// ── A stand-in for the dinkhunt analysis sidecar ─────────────────────────────

/** How the sidecar answers: `#online` with fixture results; `#offline` as if
 nothing listens on :3003; `#rejectsCourt` refuses a calibration;
 `#noTestClip` has no test_challenge.mov; `#noBounces` finds nothing. */
@genType
type sidecar = [#online | #offline | #rejectsCourt | #noTestClip | #noBounces]

// The Challenge test clip: the rally rendered small and encoded to a file,
// with the analysis the server would return for it.
let clipWidth = 960
let clipHeight = 540
let clipSeconds = 8.5
let clipFps = 30.

let clipScene = () => makeScene(~camera=baselineCamera, ~width=clipWidth, ~height=clipHeight)

let footprint = (scene, (x, y)) =>
  Array.fromInitializer(~length=16, i => {
    let a = Int.toFloat(i) /. 16. *. 2. *. Math.Constants.pi
    project(scene, (x +. 0.14 *. Math.cos(a), y +. 0.14 *. Math.sin(a)))->Option.map(((px, py)) => [
      px,
      py,
    ])
  })->Array.filterMap(p => p)

/** The analysis the sidecar returns for the test clip: its bounces (every
 other rally waypoint that lands in the clip) and the ball path per shot. */
let clipAnalysis = (~withBounces: bool): JSON.t => {
  let scene = clipScene()
  let bounces =
    rally
    ->Array.filterWithIndex((w, i) => mod(i, 2) == 1 && w.z == 0. && w.t < clipSeconds)
    ->Array.filterMap(w => project(scene, (w.x, w.y))->Option.map(pixel => (w, pixel)))
    ->Array.mapWithIndex(((w, (px, py)), i) => {
      "i": i,
      "t": w.t,
      "frame": Math.round(w.t *. clipFps)->Float.toInt,
      "world": [w.x, w.y, 0.],
      "pixel": [px, py],
      "footprint": footprint(scene, (w.x, w.y)),
    })
  // One path per shot: from a contact to the next contact (the last waypoint
  // is the ball rolling away, not a shot).
  let last = rally->Array.length - 1
  let shots =
    rally
    ->Array.filterWithIndex((w, i) => mod(i, 2) == 0 && i < last && w.t < clipSeconds)
    ->Array.map(w => w.t)
  let paths = shots->Array.mapWithIndex((start, i) => {
    let stop = shots->Array.get(i + 1)->Option.getOr(7.9)
    let frames = Math.floor((stop -. start) *. clipFps)->Float.toInt
    Array.fromInitializer(~length=frames + 1, f => {
      let t = start +. Int.toFloat(f) /. clipFps
      ballSprite(scene, t)->Option.map(b => {"t": t, "x": b.x, "y": b.y})
    })->Array.filterMap(p => p)
  })
  let analysis = {
    "width": clipWidth,
    "height": clipHeight,
    "fps": clipFps,
    "bounces": withBounces ? bounces : [],
    "paths": withBounces ? paths : [],
    "frameTimes": [],
  }
  analysis->JSON.stringifyAny->Option.getOr("{}")->JSON.parseExn
}

// Renders `seconds` of the rally into a video file with mediabunny (the
// kiosk's own muxer), offline and frame by frame, so the file has a real
// duration. H.264/MP4 where the browser can encode it, else VP9/WebM.
type blob

let encodeClip: (renderer, float, float) => promise<blob> = %raw(`
  async function (renderer, seconds, fps) {
    const mb = await import("mediabunny");
    const { width, height } = renderer.canvas;
    const codec = await mb.getFirstEncodableVideoCodec(["avc", "vp9", "vp8"], { width, height });
    if (!codec) throw new Error("no encodable video codec");
    const mp4 = codec === "avc";
    const target = new mb.BufferTarget();
    const output = new mb.Output({
      format: mp4 ? new mb.Mp4OutputFormat({ fastStart: "in-memory" }) : new mb.WebMOutputFormat(),
      target,
    });
    const source = new mb.CanvasSource(renderer.canvas, { codec, bitrate: mb.QUALITY_MEDIUM });
    output.addVideoTrack(source, { frameRate: fps });
    await output.start();
    const frames = Math.round(seconds * fps);
    for (let i = 0; i < frames; i++) {
      renderer.paint(i / fps);
      await source.add(i / fps, 1 / fps);
    }
    await output.finalize();
    return new Blob([target.buffer], { type: mp4 ? "video/mp4" : "video/webm" });
  }
`)

let testClip = () => {
  let scene = clipScene()
  let renderer = makeRenderer(scene.width, scene.height, backdrop(scene), t => ballSprite(scene, t))
  encodeClip(renderer, clipSeconds, clipFps)
}

type courtAnswer = {ok: bool, solved: bool, message: string}

let installSidecar: (
  string,
  string,
  unit => promise<blob>,
  bool => JSON.t,
  courtAnswer,
) => unit => unit = %raw(`
  function (base, mode, makeClip, analysis, court) {
    const original = window.fetch;
    const json = (body, status = 200) =>
      new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
    let clip;
    window.fetch = async function (input, init) {
      const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
      if (!url.startsWith(base)) return original.apply(this, arguments);
      if (mode === "offline") throw new TypeError("Failed to fetch");
      const path = url.slice(base.length);
      if (path.startsWith("/testclip")) {
        if (mode === "noTestClip") return new Response("not found", { status: 404 });
        clip ??= makeClip();
        return new Response(await clip, { status: 200 });
      }
      if (path.startsWith("/clips")) return json({ path: "clips/kiosk-story.mp4", calibrated: true });
      if (path.startsWith("/graphql")) {
        const query = JSON.parse(init?.body ?? "{}").query ?? "";
        if (query.includes("setKioskCourt")) return json({ data: { setKioskCourt: court } });
        const found = analysis(mode !== "noBounces");
        if (query.includes("challenge(")) return json({ data: { challenge: found } });
        if (query.includes("groundBounces")) return json({ data: { groundBounces: found.bounces } });
      }
      return json({ errors: [{ message: "unknown request " + path }] }, 400);
    };
    return () => {
      window.fetch = original;
    };
  }
`)

/** Answers the kiosk's calls to the analysis sidecar for as long as the story
 is mounted. Every mode keeps the story off the real localhost:3003. */
let useSidecar = (mode: sidecar) =>
  useInstalled(() =>
    installSidecar(
      DinkHunt.base,
      (mode :> string),
      testClip,
      withBounces => clipAnalysis(~withBounces),
      switch mode {
      | #rejectsCourt => {
          ok: false,
          solved: false,
          message: "Pose solve failed: reprojection error 41.7 px (limit 8 px). Re-check FAR L and FAR R.",
        }
      | _ => {ok: true, solved: true, message: "Court saved; pose solved (reprojection 1.9 px)."}
      },
    )
  )

// ── A stand-in for the Google Places SDK ─────────────────────────────────────

type venue = {
  placeId: string,
  name: string,
  address: string,
  lat: float,
  lng: float,
  keywords: string,
}

/** Tokyo venues the fake Places search knows about. */
let venues = [
  {
    placeId: "ChIJ-story-minato",
    name: "Minato Sports Center",
    address: "1-16-13 Shibaura, Minato City, Tokyo",
    lat: 35.6453,
    lng: 139.7527,
    keywords: "港区スポーツセンター gym pickleball",
  },
  {
    placeId: "ChIJ-story-tokyo-gym",
    name: "Tokyo Metropolitan Gymnasium",
    address: "1-17-1 Sendagaya, Shibuya City, Tokyo",
    lat: 35.6812,
    lng: 139.7125,
    keywords: "東京体育館 gym sports",
  },
  {
    placeId: "ChIJ-story-shibuya",
    name: "Shibuya Sports Center",
    address: "1-40-18 Nishihara, Shibuya City, Tokyo",
    lat: 35.6784,
    lng: 139.6832,
    keywords: "渋谷区スポーツセンター gym sports",
  },
  {
    placeId: "ChIJ-story-ariake",
    name: "Ariake Tennis Forest Park",
    address: "2-2-22 Ariake, Koto City, Tokyo",
    lat: 35.638,
    lng: 139.789,
    keywords: "有明テニスの森 tennis courts",
  },
  {
    placeId: "ChIJ-story-komazawa",
    name: "Komazawa Olympic Park General Sports Ground Gymnasium",
    address: "1-1 Komazawakoen, Setagaya City, Tokyo",
    lat: 35.6254,
    lng: 139.6617,
    keywords: "駒沢オリンピック公園 gym sports",
  },
  {
    placeId: "ChIJ-story-toyosu",
    name: "Toyosu Pickleball Courts",
    address: "6-1-23 Toyosu, Koto City, Tokyo",
    lat: 35.6456,
    lng: 139.7843,
    keywords: "豊洲 pickleball courts",
  },
  {
    placeId: "ChIJ-story-shinagawa",
    name: "Shinagawa Pickleball Club House",
    address: "2-18-1 Konan, Minato City, Tokyo",
    lat: 35.6284,
    lng: 139.7387,
    keywords: "品川 pickleball indoor",
  },
]

type placesAnswer = [#answers | #unavailable]

let installPlaces: (array<venue>, string) => unit => unit = %raw(`
  function (venues, mode) {
    const had = Object.prototype.hasOwnProperty.call(window, "google");
    const previous = window.google;
    const latLng = (lat, lng) => ({ lat: () => lat, lng: () => lng });
    const place = (v) => ({
      id: v.placeId,
      displayName: v.name,
      formattedAddress: v.address,
      location: latLng(v.lat, v.lng),
    });
    const matches = (text) => {
      const words = text.toLowerCase().split(/\s+/).filter(Boolean);
      return venues.filter((v) => {
        const haystack = (v.name + " " + v.address + " " + v.keywords).toLowerCase();
        return words.every((w) => haystack.includes(w));
      });
    };
    const prediction = (v) => ({
      placeId: v.placeId,
      text: { text: v.name + ", " + v.address },
      mainText: { text: v.name },
      secondaryText: { text: v.address },
      toPlace: () => ({ ...place(v), fetchFields: async () => ({ place: place(v) }) }),
    });
    const places = {
      AutocompleteSessionToken: class AutocompleteSessionToken {},
      AutocompleteSuggestion: {
        fetchAutocompleteSuggestions: async ({ input }) => {
          if (mode === "unavailable") throw new Error("Places API (New) has not been enabled (story fixture)");
          return { suggestions: matches(input).slice(0, 5).map((v) => ({ placePrediction: prediction(v) })) };
        },
      },
      Place: {
        searchByText: async ({ textQuery }) => ({ places: matches(textQuery).slice(0, 1).map(place) }),
      },
    };
    window.google = { ...(previous ?? {}), maps: { ...(previous?.maps ?? {}), places } };
    return () => {
      if (had) window.google = previous;
      else delete window.google;
    };
  }
`)

// What @vis.gl/react-google-maps' APIProvider puts in context once the Maps
// script and the "places" library have loaded; useMapsLibrary reads it.
type mapsContextValue
@module("@vis.gl/react-google-maps")
external mapsContext: React.Context.t<mapsContextValue> = "APIProviderContext"

let loadedPlacesContext: unit => mapsContextValue = %raw(`
  function () {
    const places = window.google.maps.places;
    return {
      status: "LOADED",
      loadedLibraries: { places },
      importLibrary: async () => places,
      mapInstances: {},
      addMapInstance: () => {},
      removeMapInstance: () => {},
      clearMapInstances: () => {},
    };
  }
`)

module PlacesProvider = {
  let provider = React.Context.provider(mapsContext)

  /** Children see a loaded Places library that answers from `venues`. */
  @react.component
  let make = (~answer: placesAnswer=#answers, ~children) => {
    useInstalled(() => installPlaces(venues, (answer :> string)))
    let (value, _) = React.useState(() => loadedPlacesContext())
    React.createElement(provider, {value, children})
  }
}
