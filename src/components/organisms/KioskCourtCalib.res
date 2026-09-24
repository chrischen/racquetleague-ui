// Court calibration overlay for the kiosk — mirrors the python drag-to-fit UI
// (main.py court / lib.court_calib.manual_court_fit):
//
// - EVERY ground landmark is a draggable handle. Dragging one ANCHORS it;
//   the court fit re-solves live and the un-anchored handles plus the full
//   court wireframe ride the fit (python: "follows the fit; drag to anchor").
// - Any >= 4 anchors define a full perspective homography — so a court whose
//   baselines are cropped out of frame calibrates from the KITCHEN points
//   alone, exactly like the python picker (tpbt was calibrated that way).
//   With 1-3 anchors the default quad just translates (a cheap stand-in for
//   python's translate/similarity/affine ladder — full perspective needs 4).
// - Confirm sends only the ANCHORED points as seeds; the server solves the
//   pose with the same code path as `main.py court` accept.
//
// Coordinates are NATIVE video pixels throughout (the space clips are muxed
// in); the SVG carries a native-pixel viewBox over the letterboxed video, so
// drags map through one rect transform.

@val @scope("localStorage") external getStoredItem: string => Nullable.t<string> = "getItem"
@val @scope("localStorage") external setStoredItem: (string, string) => unit = "setItem"

type domRect = {left: float, top: float, width: float, height: float}
@send external getBoundingClientRect: Dom.element => domRect = "getBoundingClientRect"

let cornersStorageKey = "kiosk.courtAnchors"

// ── Loupe + reticle plumbing (ported from the labeler's court annotator) ──────
// Handles are reticles (thin ring, four ticks that stop short of the centre,
// a 1 px dot) so the pixel being placed is never covered — and on a touch
// kiosk the finger covers it anyway, so selecting/dragging a handle opens a
// 240 px magnifier of the LIVE frame in a corner, with the fitted court lines,
// the native pixel outline and a gap crosshair at the exact sub-pixel point.

let loupeStorageKey = "kiosk.loupeZoom"
let loupeCss = 240. // CSS px, square
let zoomSteps = [4., 6., 8., 12., 16.]

let loadZoom = () =>
  getStoredItem(loupeStorageKey)
  ->Nullable.toOption
  ->Option.flatMap(Float.fromString)
  ->Option.getOr(8.)

// The next/previous zoom step from the nearest step to `zoom`.
let stepZoom = (zoom: float, direction: int) => {
  let nearest = zoomSteps->Array.reduceWithIndex(0, (best, z, i) =>
    Math.abs(z -. zoom) < Math.abs(zoomSteps->Array.getUnsafe(best) -. zoom) ? i : best
  )
  let next = Math.Int.max(0, Math.Int.min(zoomSteps->Array.length - 1, nearest + direction))
  zoomSteps->Array.getUnsafe(next)
}

@val @scope("window") external devicePixelRatio: float = "devicePixelRatio"
@val external requestAnimationFrame: (float => unit) => int = "requestAnimationFrame"
@val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"

type keyEvent = {key: string}
@val @scope("window")
external addKeyListener: (@as("keydown") _, keyEvent => unit) => unit = "addEventListener"
@val @scope("window")
external removeKeyListener: (@as("keydown") _, keyEvent => unit) => unit = "removeEventListener"
@val @scope("window")
external addResizeListener: (@as("resize") _, unit => unit) => unit = "addEventListener"
@val @scope("window")
external removeResizeListener: (@as("resize") _, unit => unit) => unit = "removeEventListener"

// Canvas 2D, only what the loupe needs.
type ctx2d
@send external getContext2d: (Dom.element, @as("2d") _) => Nullable.t<ctx2d> = "getContext"
@set external setCanvasWidth: (Dom.element, int) => unit = "width"
@set external setCanvasHeight: (Dom.element, int) => unit = "height"
@set external setImageSmoothing: (ctx2d, bool) => unit = "imageSmoothingEnabled"
@set external setFillStyle: (ctx2d, string) => unit = "fillStyle"
@set external setStrokeStyle: (ctx2d, string) => unit = "strokeStyle"
@set external setLineWidth: (ctx2d, float) => unit = "lineWidth"
@set external setFont: (ctx2d, string) => unit = "font"
@send external setLineDash: (ctx2d, array<float>) => unit = "setLineDash"
@send external fillRect: (ctx2d, float, float, float, float) => unit = "fillRect"
@send
external drawImageCrop: (
  ctx2d,
  Dom.element,
  float,
  float,
  float,
  float,
  float,
  float,
  float,
  float,
) => unit = "drawImage"
@send external beginPath: ctx2d => unit = "beginPath"
@send external ctxMoveTo: (ctx2d, float, float) => unit = "moveTo"
@send external ctxLineTo: (ctx2d, float, float) => unit = "lineTo"
@send external strokePath: ctx2d => unit = "stroke"
@send external fillPath: ctx2d => unit = "fill"
@send external arc: (ctx2d, float, float, float, float, float) => unit = "arc"
@send external fillText: (ctx2d, string, float, float) => unit = "fillText"

// The hidden live-frame source the loupe crops from.
@get external videoWidth: Dom.element => int = "videoWidth"
@get external videoHeight: Dom.element => int = "videoHeight"
@set external setMuted: (Dom.element, bool) => unit = "muted"
@set external setPlaysInline: (Dom.element, bool) => unit = "playsInline"
@send external playVideo: Dom.element => promise<unit> = "play"

let isSelfTarget: ReactEvent.Pointer.t => bool = %raw(`e => e.target === e.currentTarget`)

// ── Court model (lib/court.py constants; metres, +Y toward the near side) ────

let halfWid = 3.05 // COURT_WIDTH 6.10 / 2
let halfLen = 6.705 // COURT_LENGTH 13.41 / 2
let kitchenDepth = 2.13

// The draggable anchor catalog: name -> ground-plane world position.
let anchors: array<(string, (float, float))> = [
  ("near_baseline_left", (-.halfWid, halfLen)),
  ("near_baseline_right", (halfWid, halfLen)),
  ("far_baseline_left", (-.halfWid, -.halfLen)),
  ("far_baseline_right", (halfWid, -.halfLen)),
  ("near_kitchen_left", (-.halfWid, kitchenDepth)),
  ("near_kitchen_right", (halfWid, kitchenDepth)),
  ("far_kitchen_left", (-.halfWid, -.kitchenDepth)),
  ("far_kitchen_right", (halfWid, -.kitchenDepth)),
  ("near_kitchen_centre", (0., kitchenDepth)),
  ("far_kitchen_centre", (0., -.kitchenDepth)),
  // Net post bases: precise, visible in any side-of-court framing.
  ("net_left", (-.halfWid, 0.)),
  ("net_right", (halfWid, 0.)),
]

let worldOf = (name: string): (float, float) =>
  anchors
  ->Array.find(((n, _)) => n == name)
  ->Option.map(((_, w)) => w)
  ->Option.getOr((0., 0.))

let anchorLabel = name =>
  switch name {
  | "near_baseline_left" => "NEAR L"
  | "near_baseline_right" => "NEAR R"
  | "far_baseline_left" => "FAR L"
  | "far_baseline_right" => "FAR R"
  | "near_kitchen_left" => "NK L"
  | "near_kitchen_right" => "NK R"
  | "far_kitchen_left" => "FK L"
  | "far_kitchen_right" => "FK R"
  | "near_kitchen_centre" => "NK C"
  | "far_kitchen_centre" => "FK C"
  | "net_left" => "NET L"
  | "net_right" => "NET R"
  | _ => name
  }

// The wireframe drawn from the live fit: court outline, kitchen lines, net
// line, and the two centre lines (kitchen line to baseline on each side).
let segments: array<((float, float), (float, float))> = [
  ((-.halfWid, halfLen), (halfWid, halfLen)), // near baseline
  ((-.halfWid, -.halfLen), (halfWid, -.halfLen)), // far baseline
  ((-.halfWid, halfLen), (-.halfWid, -.halfLen)), // left sideline
  ((halfWid, halfLen), (halfWid, -.halfLen)), // right sideline
  ((-.halfWid, kitchenDepth), (halfWid, kitchenDepth)), // near kitchen line
  ((-.halfWid, -.kitchenDepth), (halfWid, -.kitchenDepth)), // far kitchen line
  ((-.halfWid, 0.), (halfWid, 0.)), // net (ground projection)
  ((0., kitchenDepth), (0., halfLen)), // near centre line
  ((0., -.kitchenDepth), (0., -.halfLen)), // far centre line
]

// ── Homography (world ground plane -> image px), least-squares DLT ───────────

// Solve the 8x8 normal equations of the standard DLT system with partial-pivot
// Gaussian elimination. Returns the 3x3 H as a flat 9-array (h22 = 1).
let solveHomography = (pairs: array<((float, float), (float, float))>): option<array<float>> =>
  if pairs->Array.length < 4 {
    None
  } else {
    // A^T A (8x8) and A^T b (8), accumulated per correspondence.
    let ata = Array.make(~length=64, 0.)
    let atb = Array.make(~length=8, 0.)
    let addRow = (row: array<float>, b: float) => {
      for i in 0 to 7 {
        let ri = row->Array.getUnsafe(i)
        atb->Array.setUnsafe(i, atb->Array.getUnsafe(i) +. ri *. b)
        for j in 0 to 7 {
          ata->Array.setUnsafe(
            i * 8 + j,
            ata->Array.getUnsafe(i * 8 + j) +. ri *. row->Array.getUnsafe(j),
          )
        }
      }
    }
    pairs->Array.forEach((((wx, wy), (px, py))) => {
      addRow([wx, wy, 1., 0., 0., 0., -.px *. wx, -.px *. wy], px)
      addRow([0., 0., 0., wx, wy, 1., -.py *. wx, -.py *. wy], py)
    })
    // Gaussian elimination with partial pivoting on [ata | atb].
    let singular = ref(false)
    for col in 0 to 7 {
      let pivot = ref(col)
      for r in col + 1 to 7 {
        if (
          Math.abs(ata->Array.getUnsafe(r * 8 + col)) >
            Math.abs(ata->Array.getUnsafe(pivot.contents * 8 + col))
        ) {
          pivot := r
        }
      }
      if Math.abs(ata->Array.getUnsafe(pivot.contents * 8 + col)) < 1e-9 {
        singular := true
      } else {
        if pivot.contents != col {
          for j in 0 to 7 {
            let tmp = ata->Array.getUnsafe(col * 8 + j)
            ata->Array.setUnsafe(col * 8 + j, ata->Array.getUnsafe(pivot.contents * 8 + j))
            ata->Array.setUnsafe(pivot.contents * 8 + j, tmp)
          }
          let tmp = atb->Array.getUnsafe(col)
          atb->Array.setUnsafe(col, atb->Array.getUnsafe(pivot.contents))
          atb->Array.setUnsafe(pivot.contents, tmp)
        }
        for r in col + 1 to 7 {
          let factor = ata->Array.getUnsafe(r * 8 + col) /. ata->Array.getUnsafe(col * 8 + col)
          if factor != 0. {
            for j in col to 7 {
              ata->Array.setUnsafe(
                r * 8 + j,
                ata->Array.getUnsafe(r * 8 + j) -. factor *. ata->Array.getUnsafe(col * 8 + j),
              )
            }
            atb->Array.setUnsafe(r, atb->Array.getUnsafe(r) -. factor *. atb->Array.getUnsafe(col))
          }
        }
      }
    }
    if singular.contents {
      None
    } else {
      let h = Array.make(~length=9, 0.)
      h->Array.setUnsafe(8, 1.)
      for i in 0 to 7 {
        let row = 7 - i
        let acc = ref(atb->Array.getUnsafe(row))
        for j in row + 1 to 7 {
          acc :=
            acc.contents -. ata->Array.getUnsafe(row * 8 + j) *. h->Array.getUnsafe(j)
        }
        h->Array.setUnsafe(row, acc.contents /. ata->Array.getUnsafe(row * 8 + row))
      }
      Some(h)
    }
  }

// Homogeneous projection (x, y, w) — NOT yet divided. w <= 0 means the world
// point is behind the camera / beyond the horizon, and a plain divide draws
// it FLIPPED: from a side-of-court camera the out-of-frame baselines rendered
// as lines across the top of the image. With h22 fixed to 1 by the solver,
// the net centre (world origin) has w = 1, so the sign is meaningful for any
// camera that can see the net.
let projectHomogeneous = (h: array<float>, (wx, wy): (float, float)): (float, float, float) => (
  h->Array.getUnsafe(0) *. wx +. h->Array.getUnsafe(1) *. wy +. h->Array.getUnsafe(2),
  h->Array.getUnsafe(3) *. wx +. h->Array.getUnsafe(4) *. wy +. h->Array.getUnsafe(5),
  h->Array.getUnsafe(6) *. wx +. h->Array.getUnsafe(7) *. wy +. h->Array.getUnsafe(8),
)

// Points closer to the horizon than this are treated as invisible. 0.01 of
// the origin's w puts them ~100x outside the frame — the SVG viewport clips
// the line at its true angle, without the flip.
let wEps = 0.01

// Visible pixel position, or None when the point is beyond the horizon.
let projectVisible = (h: array<float>, w: (float, float)): option<(float, float)> => {
  let (x, y, d) = projectHomogeneous(h, w)
  d > wEps ? Some((x /. d, y /. d)) : None
}

// A world segment clipped to the visible half-space (w > wEps) BEFORE the
// divide. Interpolation is linear in homogeneous coordinates, which is exact
// for a projective map of a straight line.
let projectSegment = (
  h: array<float>,
  wa: (float, float),
  wb: (float, float),
): option<((float, float), (float, float))> => {
  let (xa, ya, da) = projectHomogeneous(h, wa)
  let (xb, yb, db) = projectHomogeneous(h, wb)
  if da <= wEps && db <= wEps {
    None
  } else {
    let clip = (xv, yv, dv, xh, yh, dh) => {
      // from the visible end (v) toward the hidden end (h): where w hits wEps
      let t = (dv -. wEps) /. (dv -. dh)
      (xv +. (xh -. xv) *. t, yv +. (yh -. yv) *. t, wEps)
    }
    let (xa2, ya2, da2) = da <= wEps ? clip(xb, yb, db, xa, ya, da) : (xa, ya, da)
    let (xb2, yb2, db2) = db <= wEps ? clip(xa, ya, da, xb, yb, db) : (xb, yb, db)
    Some(((xa2 /. da2, ya2 /. da2), (xb2 /. db2, yb2 /. db2)))
  }
}

// Kept for the fit's own use (mean-offset translation of the default quad),
// where the points are the visible default corners.
let projectWith = (h: array<float>, w: (float, float)): (float, float) =>
  switch projectVisible(h, w) {
  | Some(p) => p
  | None => {
      let (x, y, d) = projectHomogeneous(h, w)
      let d = Math.abs(d) < 1e-9 ? 1e-9 : d
      (x /. d, y /. d)
    }
  }

// ── Persistence ──────────────────────────────────────────────────────────────

type placedAnchor = {name: string, x: float, y: float}

// Anchors are native pixels, so they are only meaningful on the frame size
// they were dragged on: the set is stored with that size and ignored on any
// other (a camera mode change — e.g. the 640x480 browser default giving way
// to 1080p — would otherwise replay a stale set at the wrong scale).  A
// pre-stamp entry (bare array) fails the size match and is dropped too.
type storedAnchors = {width?: int, height?: int, placed?: array<placedAnchor>}

external storedFromJson: Js.Json.t => storedAnchors = "%identity"

let loadStoredPlaced = (~width: int, ~height: int): option<array<placedAnchor>> =>
  switch getStoredItem(cornersStorageKey)->Nullable.toOption {
  | Some(raw) =>
    try {
      let stored = storedFromJson(Js.Json.parseExn(raw))
      switch (stored.width, stored.height, stored.placed) {
      | (Some(w), Some(h), Some(placed)) if w == width && h == height && placed->Array.length >= 4 =>
        Some(placed)
      | _ => None
      }
    } catch {
    | _ => None
    }
  | None => None
  }

let storePlaced = (~width: int, ~height: int, placed: array<placedAnchor>) =>
  switch Js.Json.stringifyAny({width, height, placed}) {
  | Some(raw) => setStoredItem(cornersStorageKey, raw)
  | None => ()
  }

// ── Analysis crop ────────────────────────────────────────────────────────────
// The part of the frame worth analysing: the fitted court plus headroom for
// the ball in flight. Challenge clips are cropped to it before upload — the
// server's detector resizes whatever it gets to 512x288, so the court lands on
// ~2-3x more detector pixels while the wide-angle periphery (a source of false
// detections) is gone. Deliberately a rectangle, not the court polygon: the
// ball spends most of a rally ABOVE the lines. The calibration is sent to the
// server in this rectangle's coordinates so the court pkl matches the cropped
// clips' frame size.

let headroomFrac = 0.6 // above the court's projected extent, for lobs
let sideFrac = 0.12
let footFrac = 0.10
let minCropFrac = 0.15 // never crop tighter than this fraction of an axis

let cropRegion = (placed: array<placedAnchor>, nativeW: int, nativeH: int): option<ClipCrop.rect> => {
  let pairs = placed->Array.map(a => (worldOf(a.name), (a.x, a.y)))
  switch pairs->Array.length >= 4 ? solveHomography(pairs) : None {
  | None => None
  | Some(h) => {
      let fw = Int.toFloat(nativeW)
      let fh = Int.toFloat(nativeH)
      let clampX = v => Math.max(0., Math.min(fw, v))
      let clampY = v => Math.max(0., Math.min(fh, v))
      // Every court landmark the fit can place in front of the horizon,
      // clamped into the frame (off-frame baselines just pull to the edge).
      let points =
        anchors
        ->Array.filterMap(((_, w)) => projectVisible(h, w))
        ->Array.map(((x, y)) => (clampX(x), clampY(y)))
      if points->Array.length < 4 {
        None
      } else {
        let minX = points->Array.reduce(fw, (acc, (x, _)) => Math.min(acc, x))
        let maxX = points->Array.reduce(0., (acc, (x, _)) => Math.max(acc, x))
        let minY = points->Array.reduce(fh, (acc, (_, y)) => Math.min(acc, y))
        let maxY = points->Array.reduce(0., (acc, (_, y)) => Math.max(acc, y))
        let w = maxX -. minX
        let hgt = maxY -. minY
        if w < 1. || hgt < 1. {
          None
        } else {
          let floorEven = v => {
            let i = Math.floor(Math.max(0., v))->Float.toInt
            i - mod(i, 2)
          }
          let x0 = floorEven(clampX(minX -. sideFrac *. w))
          let y0 = floorEven(clampY(minY -. headroomFrac *. hgt))
          let x1 = clampX(maxX +. sideFrac *. w)
          let y1 = clampY(maxY +. footFrac *. hgt)
          let cw = floorEven(x1 -. Int.toFloat(x0))
          let ch = floorEven(y1 -. Int.toFloat(y0))
          if Int.toFloat(cw) < minCropFrac *. fw || Int.toFloat(ch) < minCropFrac *. fh {
            None
          } else if cw >= nativeW - 2 && ch >= nativeH - 2 {
            None // the court fills the frame: nothing to gain
          } else {
            Some({ClipCrop.x: x0, y: y0, width: cw, height: ch})
          }
        }
      }
    }
  }
}

type status = Idle | Saving | Failed(string)

// The default fit: a plausible perspective trapezoid of the baseline quad.
let defaultPairs = (nativeW: float, nativeH: float): array<
  ((float, float), (float, float)),
> => [
  ((-.halfWid, halfLen), (0.18 *. nativeW, 0.86 *. nativeH)),
  ((halfWid, halfLen), (0.82 *. nativeW, 0.86 *. nativeH)),
  ((halfWid, -.halfLen), (0.68 *. nativeW, 0.34 *. nativeH)),
  ((-.halfWid, -.halfLen), (0.32 *. nativeW, 0.34 *. nativeH)),
]

@react.component
let make = (~stream: option<UserMedia.t>, ~onDone: unit => unit) => {
  let (nativeW, nativeH) = switch stream->Option.flatMap(UserMedia.videoSize) {
  | Some((w, h)) => (w->Int.toFloat, h->Int.toFloat)
  | None => (1920., 1080.)
  }

  let (placed, setPlaced) = React.useState(() =>
    switch loadStoredPlaced(~width=nativeW->Float.toInt, ~height=nativeH->Float.toInt) {
    | Some(stored) => stored
    | None => []
    }
  )
  let (dragging, setDragging) = React.useState(() => (None: option<string>))
  let (saveStatus, setSaveStatus) = React.useState(() => Idle)
  let containerRef = React.useRef(Nullable.null)
  // The handle under inspection: set on touch, kept after release so the
  // loupe stays up for fine adjustment; cleared by tapping empty court or ×.
  let (selected, setSelected) = React.useState(() => (None: option<string>))
  let (zoom, setZoomState) = React.useState(() => loadZoom())
  let setZoom = (z: float) => {
    let z = Math.max(4., Math.min(16., z))
    setZoomState(_ => z)
    setStoredItem(loupeStorageKey, Float.toString(z))
  }
  // Rendered px per native px: reticle geometry is specified in SCREEN px
  // (thin ring, 3 px tick gap) and the SVG lives in a native-px viewBox.
  let (screenScale, setScreenScale) = React.useState(() => 1.)
  let loupeCanvasRef = React.useRef(Nullable.null)
  let loupeVideoRef = React.useRef(Nullable.null)

  // The live fit, python-style: >=4 anchors -> homography from the anchors;
  // fewer -> the default quad translated by the anchors' mean offset.
  let fit = {
    let anchorPairs = placed->Array.map(a => (worldOf(a.name), (a.x, a.y)))
    switch anchorPairs->Array.length >= 4 ? solveHomography(anchorPairs) : None {
    | Some(h) => h
    | None => {
        let base = defaultPairs(nativeW, nativeH)
        let h0 = solveHomography(base)->Option.getExn // fixed quad: never singular
        switch placed->Array.length {
        | 0 => h0
        | _ => {
            let (dx, dy) = placed->Array.reduce((0., 0.), ((ax, ay), a) => {
              let (px, py) = projectWith(h0, worldOf(a.name))
              (ax +. (a.x -. px), ay +. (a.y -. py))
            })
            let n = placed->Array.length->Int.toFloat
            solveHomography(
              base->Array.map(((w, (px, py))) => (w, (px +. dx /. n, py +. dy /. n))),
            )->Option.getOr(h0)
          }
        }
      }
    }
  }

  // Anchored handles sit where the user put them; the rest ride the fit and
  // vanish (no handle, no label) when the fit puts them beyond the horizon.
  let positionOf = (name: string): option<(float, float)> =>
    switch placed->Array.find(a => a.name == name) {
    | Some(a) => Some((a.x, a.y))
    | None => projectVisible(fit, worldOf(name))
    }

  let contentBox = (rect: domRect) => {
    let scale = Math.min(rect.width /. nativeW, rect.height /. nativeH)
    let w = nativeW *. scale
    let h = nativeH *. scale
    (rect.left +. (rect.width -. w) /. 2., rect.top +. (rect.height -. h) /. 2., w, h)
  }

  React.useEffect1(() => {
    let measure = () =>
      switch containerRef.current->Nullable.toOption {
      | Some(el) => {
          let (_, _, w, _) = contentBox(el->getBoundingClientRect)
          if w > 0. {
            setScreenScale(_ => w /. nativeW)
          }
        }
      | None => ()
      }
    measure()
    addResizeListener(measure)
    Some(() => removeResizeListener(measure))
  }, [nativeW])

  // The loupe's own copy of the camera feed (drawing from the visible player
  // would couple this overlay to its DOM); 1 px and transparent, but present
  // so every engine keeps decoding it.
  React.useEffect1(() => {
    switch (loupeVideoRef.current->Nullable.toOption, stream) {
    | (Some(video), Some(source)) => {
        video->setMuted(true)
        video->setPlaysInline(true)
        video->UserMedia.setSrcObject(Nullable.make(source))
        video->playVideo->Promise.catch(_ => Promise.resolve())->ignore
      }
    | _ => ()
    }
    None
  }, [stream])

  // [ and ] step the zoom (desktop); the loupe also carries ± buttons for touch.
  React.useEffect1(() => {
    let onKey = (event: keyEvent) =>
      switch event.key {
      | "[" => setZoom(stepZoom(zoom, -1))
      | "]" => setZoom(stepZoom(zoom, 1))
      | _ => ()
      }
    addKeyListener(onKey)
    Some(() => removeKeyListener(onKey))
  }, [zoom])

  let moveTo = (name: string, clientX: float, clientY: float) =>
    switch containerRef.current->Nullable.toOption {
    | Some(el) => {
        let (bx, by, bw, bh) = contentBox(getBoundingClientRect(el))
        let x = Math.max(0., Math.min(nativeW, (clientX -. bx) /. bw *. nativeW))
        let y = Math.max(0., Math.min(nativeH, (clientY -. by) /. bh *. nativeH))
        setPlaced(previous =>
          switch previous->Array.find(a => a.name == name) {
          | Some(_) => previous->Array.map(a => a.name == name ? {...a, x, y} : a)
          | None => previous->Array.concat([{name, x, y}])
          }
        )
      }
    | None => ()
    }

  let confirm = () => {
    setSaveStatus(_ => Saving)
    let run = async () => {
      let corners = placed->Array.map((a): DinkHunt.courtCorner => {name: a.name, x: a.x, y: a.y})
      // Challenge clips are cropped to the analysis region before upload, so
      // the server's court pkl must live in that region's pixel space (it is
      // matched to clips by frame size).
      let (width, height, corners) = switch cropRegion(
        placed,
        nativeW->Float.toInt,
        nativeH->Float.toInt,
      ) {
      | Some(r) => (
          r.width,
          r.height,
          corners->Array.map(c => {...c, x: c.x -. Int.toFloat(r.x), y: c.y -. Int.toFloat(r.y)}),
        )
      | None => (nativeW->Float.toInt, nativeH->Float.toInt, corners)
      }
      switch await DinkHunt.setKioskCourt(~width, ~height, ~corners) {
      | Ok(result) if result.ok => {
          storePlaced(~width=nativeW->Float.toInt, ~height=nativeH->Float.toInt, placed)
          setSaveStatus(_ => Idle)
          onDone()
        }
      | Ok(result) => setSaveStatus(_ => Failed(result.message))
      | Error(message) => setSaveStatus(_ => Failed(message))
      }
    }
    run()->ignore
  }

  // Draw one loupe frame: a pixelated crop of the live frame around (x, y),
  // the fitted court lines dashed through it, the native pixel the point
  // falls in, and a gap crosshair meeting at the exact sub-pixel position.
  let drawLoupe = (name: string, x: float, y: float) =>
    switch (loupeCanvasRef.current->Nullable.toOption, loupeVideoRef.current->Nullable.toOption) {
    | (Some(canvas), Some(video)) if video->videoWidth > 0 => {
        let dpr = Math.min(2., devicePixelRatio)
        let cs = loupeCss *. dpr
        canvas->setCanvasWidth(Float.toInt(cs))
        canvas->setCanvasHeight(Float.toInt(cs))
        switch canvas->getContext2d->Nullable.toOption {
        | None => ()
        | Some(ctx) => {
            let z = zoom *. dpr // loupe px per native px
            let half = cs /. 2. /. z // native px from centre to edge
            let sx = x -. half
            let sy = y -. half
            // The source may report a different size than the calibration's
            // native frame; map native → source px.
            let kx = Int.toFloat(video->videoWidth) /. nativeW
            let ky = Int.toFloat(video->videoHeight) /. nativeH
            ctx->setFillStyle("#111")
            ctx->fillRect(0., 0., cs, cs)
            ctx->setImageSmoothing(false)
            ctx->drawImageCrop(video, sx *. kx, sy *. ky, 2. *. half *. kx, 2. *. half *. ky, 0., 0., cs, cs)
            let toLoupe = ((px, py): (float, float)) => ((px -. sx) *. z, (py -. sy) *. z)
            let line = (x1, y1, x2, y2) => {
              ctx->beginPath
              ctx->ctxMoveTo(x1, y1)
              ctx->ctxLineTo(x2, y2)
              ctx->strokePath
            }
            // The fitted court lines through this neighbourhood.
            ctx->setStrokeStyle("rgba(190, 242, 100, 0.7)")
            ctx->setLineWidth(1. *. dpr)
            ctx->setLineDash([4. *. dpr, 4. *. dpr])
            segments->Array.forEach(((wa, wb)) =>
              switch projectSegment(fit, wa, wb) {
              | Some((pa, pb)) => {
                  let (x1, y1) = toLoupe(pa)
                  let (x2, y2) = toLoupe(pb)
                  line(x1, y1, x2, y2)
                }
              | None => ()
              }
            )
            ctx->setLineDash([])
            // The native pixel the point falls in, outlined.
            let (qx, qy) = toLoupe((Math.floor(x), Math.floor(y)))
            ctx->setStrokeStyle("rgba(255, 255, 255, 0.55)")
            ctx->setLineWidth(1. *. dpr)
            ctx->beginPath
            ctx->ctxMoveTo(qx, qy)
            ctx->ctxLineTo(qx +. z, qy)
            ctx->ctxLineTo(qx +. z, qy +. z)
            ctx->ctxLineTo(qx, qy +. z)
            ctx->ctxLineTo(qx, qy)
            ctx->strokePath
            // Gap crosshair (halo, then colour) and a 1 px dot at the point.
            let c = cs /. 2.
            let gap = 7. *. dpr
            ctx->setStrokeStyle("rgba(0, 0, 0, 0.65)")
            ctx->setLineWidth(3. *. dpr)
            line(0., c, c -. gap, c)
            line(c +. gap, c, cs, c)
            line(c, 0., c, c -. gap)
            line(c, c +. gap, c, cs)
            ctx->setStrokeStyle("#bef264")
            ctx->setLineWidth(1. *. dpr)
            line(0., c, c -. gap, c)
            line(c +. gap, c, cs, c)
            line(c, 0., c, c -. gap)
            line(c, c +. gap, c, cs)
            ctx->setFillStyle("#bef264")
            ctx->beginPath
            ctx->arc(c, c, 1. *. dpr, 0., Math.Constants.pi *. 2.)
            ctx->fillPath
            // Caption: landmark, coordinates to a tenth of a pixel, zoom.
            let caption =
              anchorLabel(name) ++
              "  " ++
              Float.toFixed(x, ~digits=1) ++
              ", " ++
              Float.toFixed(y, ~digits=1) ++
              "  ×" ++
              Float.toString(zoom)
            ctx->setFont(Float.toString(11. *. dpr) ++ "px ui-monospace, monospace")
            ctx->setFillStyle("rgba(0, 0, 0, 0.75)")
            ctx->fillRect(0., cs -. 18. *. dpr, cs, 18. *. dpr)
            ctx->setFillStyle("#eeeeee")
            ctx->fillText(caption, 6. *. dpr, cs -. 5. *. dpr)
          }
        }
      }
    | _ => ()
    }

  // The loupe follows the live feed: redraw every animation frame while a
  // handle is selected (placed/zoom in the deps keep the closure current).
  let loupeTarget = selected->Option.flatMap(name => positionOf(name)->Option.map(p => (name, p)))
  React.useEffect3(() => {
    switch loupeTarget {
    | None => None
    | Some((name, (x, y))) => {
        let handle = ref(None)
        let rec frame = (_: float) => {
          drawLoupe(name, x, y)
          handle := Some(requestAnimationFrame(frame))
        }
        handle := Some(requestAnimationFrame(frame))
        Some(() => handle.contents->Option.forEach(cancelAnimationFrame))
      }
    }
  }, (selected, zoom, placed))

  let fmt = Float.toString
  let anchored = placed->Array.length
  // Reticle geometry in NATIVE px for a screen-constant look.
  let sc = screenScale > 0. ? screenScale : 1.
  let ringR = 11. /. sc
  let strokeW = 1.5 /. sc
  let tickGap = 3. /. sc // the centre pixel stays visible
  let tickTip = ringR +. 4. /. sc
  let hitR = 26. /. sc // generous touch target, invisible
  let dotR = 0.75 /. sc
  let crop = cropRegion(placed, nativeW->Float.toInt, nativeH->Float.toInt)
  // Baselines beyond the horizon = the fit is extrapolating wildly (typical:
  // a side-of-court camera with only the four kitchen corners anchored).
  // Measured with ±3px drag jitter: the extrapolated baseline corners move
  // 415px; anchoring the two VISIBLE baseline corners cuts that to 99px,
  // while centres/net posts only reach ~270px — reach along the court's
  // length is what stabilises it, not more points on the same lines.
  let unstable =
    anchored >= 4 &&
      anchors->Array.some(((name, w)) =>
        String.includes(name, "baseline") &&
        !(placed->Array.some(a => a.name == name)) &&
        projectVisible(fit, w) == None
      )

  <div
    ref={ReactDOM.Ref.domRef(containerRef)}
    className="absolute inset-0 z-20 touch-none select-none"
    onPointerMove={event =>
      switch dragging {
      | Some(name) =>
        moveTo(
          name,
          ReactEvent.Pointer.clientX(event)->Int.toFloat,
          ReactEvent.Pointer.clientY(event)->Int.toFloat,
        )
      | None => ()
      }}
    onPointerUp={_ => setDragging(_ => None)}
    onPointerLeave={_ => setDragging(_ => None)}>
    <video
      ref={ReactDOM.Ref.domRef(loupeVideoRef)}
      muted=true
      playsInline=true
      autoPlay=true
      className="pointer-events-none absolute left-0 top-0 h-px w-px opacity-0"
    />
    <svg
      className="absolute inset-0 h-full w-full"
      viewBox={"0 0 " ++ fmt(nativeW) ++ " " ++ fmt(nativeH)}
      preserveAspectRatio="xMidYMid meet"
      onPointerDown={event =>
        if isSelfTarget(event) {
          setSelected(_ => None)
        }}>
      // Court wireframe, projected through the live fit.
      {segments
      ->Array.mapWithIndex((((wa, wb)), index) =>
        switch projectSegment(fit, wa, wb) {
        | Some(((x1, y1), (x2, y2))) =>
          <line
            key={index->Int.toString}
            x1={fmt(x1)}
            y1={fmt(y1)}
            x2={fmt(x2)}
            y2={fmt(y2)}
            stroke="#bef264"
            strokeWidth="3"
            strokeOpacity="0.8"
          />
        | None => React.null
        }
      )
      ->React.array}
      // The analysis region: what a Challenge clip is cropped to.
      {switch crop {
      | Some(r) =>
        <g>
          <rect
            x={r.x->Int.toString}
            y={r.y->Int.toString}
            width={r.width->Int.toString}
            height={r.height->Int.toString}
            fill="none"
            stroke="#ffffff"
            strokeWidth="3"
            strokeDasharray="16 12"
            strokeOpacity="0.75"
          />
          <text
            x={(r.x + 14)->Int.toString}
            y={(r.y + r.height - 14)->Int.toString}
            fill="#ffffff"
            fillOpacity="0.85"
            fontSize="22"
            fontWeight="800"
            fontFamily="monospace">
            {React.string("ANALYSIS REGION")}
          </text>
        </g>
      | None => React.null
      }}
      // Handles are reticles: a thin ring, four ticks that stop 3 screen px
      // short of the centre, a black halo so they read on white paint, and a
      // 1 px dot at the exact point. Solid = anchored, dashed = riding the fit.
      {anchors
      ->Array.map(((name, _)) =>
        switch positionOf(name) {
        | None => React.null
        | Some((x, y)) => {
            let isPlaced = placed->Array.some(a => a.name == name)
            let isSelected = selected == Some(name)
            let colour = "#bef264"
            let dash = isPlaced ? "" : fmt(5. /. sc)
            let tick = (dx: float, dy: float, key: string, halo: bool) =>
              <line
                key={key ++ (halo ? "h" : "")}
                x1={fmt(x +. dx *. tickGap)}
                y1={fmt(y +. dy *. tickGap)}
                x2={fmt(x +. dx *. tickTip)}
                y2={fmt(y +. dy *. tickTip)}
                stroke={halo ? "#000000" : colour}
                strokeWidth={fmt(halo ? strokeW *. 2.5 : strokeW)}
                opacity={halo ? "0.6" : "1"}
                className="pointer-events-none"
              />
            <g key=name opacity={isPlaced ? "1" : "0.8"}>
              {isSelected
                ? <circle
                    cx={fmt(x)}
                    cy={fmt(y)}
                    r={fmt(ringR +. 5. /. sc)}
                    fill="none"
                    stroke="#ffffff"
                    strokeWidth={fmt(strokeW)}
                    className="pointer-events-none"
                  />
                : React.null}
              <circle
                cx={fmt(x)}
                cy={fmt(y)}
                r={fmt(ringR)}
                fill="none"
                stroke="#000000"
                strokeWidth={fmt(strokeW *. 2.5)}
                opacity="0.5"
                className="pointer-events-none"
              />
              <circle
                cx={fmt(x)}
                cy={fmt(y)}
                r={fmt(ringR)}
                fill="none"
                stroke=colour
                strokeWidth={fmt(strokeW)}
                strokeDasharray=dash
                className="pointer-events-none"
              />
              {tick(1., 0., "e", true)}
              {tick(-1., 0., "w", true)}
              {tick(0., 1., "s", true)}
              {tick(0., -1., "n", true)}
              {tick(1., 0., "e", false)}
              {tick(-1., 0., "w", false)}
              {tick(0., 1., "s", false)}
              {tick(0., -1., "n", false)}
              <circle
                cx={fmt(x)} cy={fmt(y)} r={fmt(dotR)} fill=colour stroke="none" className="pointer-events-none"
              />
              // The touch target: invisible and generous, so a fingertip can
              // grab the reticle without covering what it marks with ink.
              <circle
                cx={fmt(x)}
                cy={fmt(y)}
                r={fmt(hitR)}
                fill="transparent"
                stroke="none"
                className="cursor-grab"
                onPointerDown={event => {
                  ReactEvent.Pointer.preventDefault(event)
                  setSelected(_ => Some(name))
                  setDragging(_ => Some(name))
                }}
              />
              <text
                x={fmt(x +. ringR +. 6. /. sc)}
                y={fmt(y -. ringR -. 2. /. sc)}
                fill={isPlaced ? "#ffffff" : "#d9f99d"}
                stroke="#000000"
                strokeWidth={fmt(3. /. sc)}
                paintOrder="stroke"
                fontSize={fmt(13. /. sc)}
                fontWeight="800"
                fontFamily="monospace"
                className="pointer-events-none select-none">
                {React.string(anchorLabel(name))}
              </text>
            </g>
          }
        }
      )
      ->React.array}
    </svg>
    {switch loupeTarget {
    | Some((_, (x, y))) => {
        // Keep the loupe out from under the handle it magnifies: top-left
        // unless the handle is there, then top-right.
        let (offX, offY) = switch containerRef.current->Nullable.toOption {
        | Some(el) => {
            let rect = el->getBoundingClientRect
            let (left, top, _, _) = contentBox(rect)
            (left -. rect.left, top -. rect.top)
          }
        | None => (0., 0.)
        }
        let hx = offX +. x *. sc
        let hy = offY +. y *. sc
        let onLeft = !(hx < loupeCss +. 24. && hy < loupeCss +. 64.)
        <div
          className={"pointer-events-none absolute top-2 z-30 flex flex-col border-2 border-white/70 bg-black shadow-2xl " ++ (
            onLeft ? "left-2" : "right-2"
          )}>
          <canvas
            ref={ReactDOM.Ref.domRef(loupeCanvasRef)}
            style={ReactDOM.Style.make(~width="240px", ~height="240px", ~display="block", ())}
          />
          <div className="pointer-events-auto flex items-center justify-between gap-1 bg-black/90 px-1 py-1">
            <button
              type_="button"
              ariaLabel="Zoom out"
              onClick={_ => setZoom(stepZoom(zoom, -1))}
              className="flex h-9 w-9 items-center justify-center border border-white/30 text-base font-extrabold text-white active:bg-white/10">
              {React.string("−")}
            </button>
            <span className="font-mono text-xs font-semibold text-white">
              {React.string("×" ++ Float.toString(zoom) ++ "  [ ]")}
            </span>
            <button
              type_="button"
              ariaLabel="Zoom in"
              onClick={_ => setZoom(stepZoom(zoom, 1))}
              className="flex h-9 w-9 items-center justify-center border border-white/30 text-base font-extrabold text-white active:bg-white/10">
              {React.string("+")}
            </button>
            <button
              type_="button"
              ariaLabel="Close magnifier"
              onClick={_ => setSelected(_ => None)}
              className="flex h-9 w-9 items-center justify-center border border-white/30 text-white active:bg-white/10">
              <Lucide.X \"aria-hidden"="true" size=16 />
            </button>
          </div>
        </div>
      }
    | None => React.null
    }}
    <div
      className="pointer-events-none absolute inset-x-0 top-0 bg-gradient-to-b from-black/85 to-transparent p-4 pb-10">
      <div className="pointer-events-auto mx-auto flex max-w-3xl flex-col gap-3">
        <div>
          <h2 className="text-xl font-extrabold text-white"> {React.string("Court setup")} </h2>
          <p className="mt-1 text-sm text-white/80">
            {React.string(
              "Drag any 4+ points onto their painted marks — the rest follow. " ++
              "Use the kitchen (NK/FK) points when the baselines are out of frame.",
            )}
          </p>
        </div>
        {unstable
          ? <p
              className="border-2 border-amber-400/40 bg-amber-500/15 px-3 py-2 text-sm font-semibold text-amber-200">
              {React.string(
                "Fit is unstable — a baseline projects beyond the horizon. " ++
                "Anchor any baseline corners you can see (FAR L/R or NEAR L/R); " ++
                "kitchen centres and net posts help less.",
              )}
            </p>
          : React.null}
        {switch saveStatus {
        | Failed(message) =>
          <p
            className="border-2 border-red-400/40 bg-red-500/20 px-3 py-2 text-sm font-semibold text-red-200">
            {React.string(message)}
          </p>
        | _ => React.null
        }}
        <div className="flex gap-3">
          <button
            type_="button"
            disabled={saveStatus == Saving || anchored < 4}
            onClick={_ => confirm()}
            className="flex min-h-14 flex-1 items-center justify-center gap-2 border-2 border-kiosk-accent bg-kiosk-accent px-5 text-lg font-extrabold text-kiosk-bg transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-accentDark disabled:opacity-50">
            {React.string(
              saveStatus == Saving
                ? "Solving pose…"
                : anchored < 4
                ? "Anchor " ++ (4 - anchored)->Int.toString ++ " more"
                : "Confirm court (" ++ anchored->Int.toString ++ " anchored)",
            )}
          </button>
          <button
            type_="button"
            onClick={_ => setPlaced(_ => [])}
            className="flex min-h-14 items-center justify-center border-2 border-white/40 bg-black/40 px-4 text-lg font-extrabold text-white active:bg-white/10">
            {React.string("Reset")}
          </button>
          <button
            type_="button"
            onClick={_ => onDone()}
            className="flex min-h-14 items-center justify-center border-2 border-white/40 bg-black/40 px-4 text-lg font-extrabold text-white active:bg-white/10">
            {React.string("Skip")}
          </button>
        </div>
      </div>
    </div>
  </div>
}
