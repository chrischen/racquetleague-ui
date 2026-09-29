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

// ── Staged court fit ─────────────────────────────────────────────────────────
// The court only follows the anchors once they actually determine it.
// Shifting the default quad by the anchors' mean offset (the old 1-3 anchor
// behaviour) dragged the whole court around — often pushing other handles off
// screen — while the user was still placing the first points. Now:
//   Unfitted     fewer than 3 usable anchors: only dragged handles move; the
//                rest stay on the default court.
//   Affine       3+ anchors including a triple NOT on one court line (and not
//                squashed onto a line in the image): a least-squares affine
//                fit moves the rest roughly into place.
//   Perspective  4+ anchors including a quad with no 3 on a line: the full
//                homography. Only this stage can be confirmed (the server's
//                pose solve needs 4 points in general position).

type fitStage = Unfitted | Affine | Perspective
type courtFit = {stage: fitStage, h: array<float>}

// The default fit: a plausible perspective trapezoid of the baseline quad.
let defaultPairs = (nativeW: float, nativeH: float): array<
  ((float, float), (float, float)),
> => [
  ((-.halfWid, halfLen), (0.18 *. nativeW, 0.86 *. nativeH)),
  ((halfWid, halfLen), (0.82 *. nativeW, 0.86 *. nativeH)),
  ((halfWid, -.halfLen), (0.68 *. nativeW, 0.34 *. nativeH)),
  ((-.halfWid, -.halfLen), (0.32 *. nativeW, 0.34 *. nativeH)),
]

let defaultFit = (nativeW: float, nativeH: float) =>
  solveHomography(defaultPairs(nativeW, nativeH))->Option.getExn // fixed quad: never singular

// Twice the signed area of a triangle.
let area2 = ((ax, ay): (float, float), (bx, by): (float, float), (cx, cy): (float, float)) =>
  (bx -. ax) *. (cy -. ay) -. (by -. ay) *. (cx -. ax)

// Court triangles that are not colinear are >= ~6.5 m² (2x area) — e.g.
// NET L, NK L, NK C — while colinear landmarks are exactly 0.
let worldMinArea2 = 1.0
// Image shape: 2x area / longest side² (0 = on a line, ~0.87 = equilateral).
let imageMinShape = 0.04
let imageMinSpanPx = 8.

// The triple's orientation sign when it can anchor a fit, 0 when it cannot.
let tripleSign = (a: placedAnchor, b: placedAnchor, c: placedAnchor): float => {
  let w = area2(worldOf(a.name), worldOf(b.name), worldOf(c.name))
  let pa = (a.x, a.y)
  let pb = (b.x, b.y)
  let pc = (c.x, c.y)
  let i = area2(pa, pb, pc)
  let d2 = ((x1, y1), (x2, y2)) => (x2 -. x1) *. (x2 -. x1) +. (y2 -. y1) *. (y2 -. y1)
  let longest = Math.max(d2(pa, pb), Math.max(d2(pb, pc), d2(pa, pc)))
  let usable =
    Math.abs(w) >= worldMinArea2 &&
    longest >= imageMinSpanPx *. imageMinSpanPx &&
    Math.abs(i) /. longest >= imageMinShape
  // Positive when the image keeps the court's orientation, negative when
  // mirrored; a homography's four triples must all agree.
  usable ? w *. i > 0. ? 1. : -1. : 0.
}

let hasAffineBasis = (placed: array<placedAnchor>): bool => {
  let n = placed->Array.length
  let found = ref(false)
  for i in 0 to n - 3 {
    for j in i + 1 to n - 2 {
      for k in j + 1 to n - 1 {
        if !found.contents {
          let g = Array.getUnsafe(placed, _)
          found := tripleSign(g(i), g(j), g(k)) != 0.
        }
      }
    }
  }
  found.contents
}

// Some 4 anchors with no 3 on a line and a consistent orientation.
let hasPerspectiveBasis = (placed: array<placedAnchor>): bool => {
  let n = placed->Array.length
  let found = ref(false)
  let g = Array.getUnsafe(placed, _)
  for i in 0 to n - 4 {
    for j in i + 1 to n - 3 {
      for k in j + 1 to n - 2 {
        for l in k + 1 to n - 1 {
          if !found.contents {
            let s = [
              tripleSign(g(i), g(j), g(k)),
              tripleSign(g(i), g(j), g(l)),
              tripleSign(g(i), g(k), g(l)),
              tripleSign(g(j), g(k), g(l)),
            ]
            found :=
              s->Array.every(v => v == 1.) || s->Array.every(v => v == -1.)
          }
        }
      }
    }
  }
  found.contents
}

// Least-squares affine map world -> image, as a 3x3 with bottom row 0 0 1
// (so every point is "in front": w = 1).
let solveAffine = (pairs: array<((float, float), (float, float))>): option<array<float>> => {
  // Normal equations: M * [a b c] = rx and M * [d e f] = ry.
  let m = Array.make(~length=9, 0.)
  let rx = Array.make(~length=3, 0.)
  let ry = Array.make(~length=3, 0.)
  pairs->Array.forEach((((wx, wy), (px, py))) => {
    let v = [wx, wy, 1.]
    for r in 0 to 2 {
      let vr = v->Array.getUnsafe(r)
      rx->Array.setUnsafe(r, rx->Array.getUnsafe(r) +. vr *. px)
      ry->Array.setUnsafe(r, ry->Array.getUnsafe(r) +. vr *. py)
      for c in 0 to 2 {
        m->Array.setUnsafe(r * 3 + c, m->Array.getUnsafe(r * 3 + c) +. vr *. v->Array.getUnsafe(c))
      }
    }
  })
  let at = (r, c) => m->Array.getUnsafe(r * 3 + c)
  let det3 = (c0: array<float>, c1: array<float>, c2: array<float>) => {
    let e = (col: array<float>, r) => col->Array.getUnsafe(r)
    e(c0, 0) *. (e(c1, 1) *. e(c2, 2) -. e(c2, 1) *. e(c1, 2)) -.
    e(c1, 0) *. (e(c0, 1) *. e(c2, 2) -. e(c2, 1) *. e(c0, 2)) +.
    e(c2, 0) *. (e(c0, 1) *. e(c1, 2) -. e(c1, 1) *. e(c0, 2))
  }
  let col = c => [at(0, c), at(1, c), at(2, c)]
  let d = det3(col(0), col(1), col(2))
  if Math.abs(d) < 1e-9 {
    None
  } else {
    // Cramer's rule.
    let solve = rhs => (
      det3(rhs, col(1), col(2)) /. d,
      det3(col(0), rhs, col(2)) /. d,
      det3(col(0), col(1), rhs) /. d,
    )
    let (a, b, c) = solve(rx)
    let (dd, e, f) = solve(ry)
    Some([a, b, c, dd, e, f, 0., 0., 1.])
  }
}

let courtFit = (placed: array<placedAnchor>, ~nativeW: float, ~nativeH: float): courtFit => {
  let pairs = placed->Array.map(a => (worldOf(a.name), (a.x, a.y)))
  let perspective =
    placed->Array.length >= 4 && hasPerspectiveBasis(placed) ? solveHomography(pairs) : None
  switch perspective {
  | Some(h) => {stage: Perspective, h}
  | None =>
    switch hasAffineBasis(placed) ? solveAffine(pairs) : None {
    | Some(h) => {stage: Affine, h}
    | None => {stage: Unfitted, h: defaultFit(nativeW, nativeH)}
    }
  }
}

// Where a handle is drawn: anchored handles sit where the user put them;
// the rest ride the fit (the untouched default court while Unfitted) and
// vanish when the fit puts them beyond the horizon.
let handlePosition = (fit: courtFit, placed: array<placedAnchor>, name: string): option<(
  float,
  float,
)> =>
  switch placed->Array.find(a => a.name == name) {
  | Some(a) => Some((a.x, a.y))
  | None => projectVisible(fit.h, worldOf(name))
  }

let cropRegion = (placed: array<placedAnchor>, nativeW: int, nativeH: int): option<ClipCrop.rect> => {
  let fit = courtFit(placed, ~nativeW=Int.toFloat(nativeW), ~nativeH=Int.toFloat(nativeH))
  switch fit.stage == Perspective ? Some(fit.h) : None {
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

// ── Solve payload ────────────────────────────────────────────────────────────
// Exactly what Confirm persists — and what the live preview solves, so the
// preview shows the calibration the analysis will actually use. Challenge
// clips are cropped to the analysis region before upload, so the server's
// court pkl must live in that region's pixel space (it is matched to clips
// by frame size); `offset` maps that space back onto the native frame.

type solvePayload = {
  width: int,
  height: int,
  corners: array<DinkHunt.courtCorner>,
  offset: (float, float),
}

let solvePayload = (placed: array<placedAnchor>, ~nativeW: int, ~nativeH: int): solvePayload => {
  let corners = placed->Array.map((a): DinkHunt.courtCorner => {name: a.name, x: a.x, y: a.y})
  switch cropRegion(placed, nativeW, nativeH) {
  | Some(r) => {
      width: r.width,
      height: r.height,
      corners: corners->Array.map(c => {
        ...c,
        x: c.x -. Int.toFloat(r.x),
        y: c.y -. Int.toFloat(r.y),
      }),
      offset: (Int.toFloat(r.x), Int.toFloat(r.y)),
    }
  | None => {width: nativeW, height: nativeH, corners, offset: (0., 0.)}
  }
}

// Identity of a payload (to 0.1 px): a preview is only shown for the exact
// anchors it was solved from.
let payloadKey = (p: solvePayload) =>
  p.width->Int.toString ++
  "x" ++
  p.height->Int.toString ++
  p.corners
  ->Array.map(c => c.name ++ "@" ++ Float.toFixed(c.x, ~digits=1) ++ "," ++ Float.toFixed(c.y, ~digits=1))
  ->Array.join(";")

// ── Lens-corrected reprojection ──────────────────────────────────────────────
// The server's solved camera (DinkHunt.kioskCamera) projects any court point
// onto the WARPED frame — the same model tools/graphql_server.KioskCamera
// documents and lib.lens.distort_points applies:
//   c = M·(x, y, 0) + t;  u = K·c / c_z;  warped = distort(u; lensK, k1)
// Unlike the kiosk's own straight-line fit, this bends court lines the way a
// wide lens does, so it is the visual proof that the correction fits.

let lensAnchorsNeeded = 6 // lib.lens: fewer anchors pin k1 to 0

let mat3 = (m: array<float>, (x, y, z): (float, float, float)): (float, float, float) => {
  let e = Array.getUnsafe(m, _)
  (
    e(0) *. x +. e(1) *. y +. e(2) *. z,
    e(3) *. x +. e(4) *. y +. e(5) *. z,
    e(6) *. x +. e(7) *. y +. e(8) *. z,
  )
}

// Court ground point -> warped pixel in the payload's space, or None when it
// is behind the camera or beyond the lens model's valid range. For barrel
// warp (k1 < 0) r·(1 + k1·r²) turns back past r² = 1/(3|k1|): points out
// there "fold" INTO the frame at wrong positions — exactly the clipped
// off-screen corners — so they are reported as not visible.
let lensProject = (cam: DinkHunt.kioskCamera, (wx, wy): (float, float)): option<(float, float)> => {
  let (cx, cy, cz) = mat3(cam.m, (wx, wy, 0.))
  let t = Array.getUnsafe(cam.t, _)
  let (cx, cy, cz) = (cx +. t(0), cy +. t(1), cz +. t(2))
  if cz <= 1e-6 {
    None
  } else {
    let (ux, uy, uw) = mat3(cam.k, (cx, cy, cz))
    let (ux, uy) = (ux /. uw, uy /. uw)
    let l = Array.getUnsafe(cam.lensK, _)
    let (fx, fy, lcx, lcy) = (l(0), l(4), l(2), l(5))
    let xn = (ux -. lcx) /. fx
    let yn = (uy -. lcy) /. fy
    let r2 = xn *. xn +. yn *. yn
    if cam.k1 < 0. && 1. +. 3. *. cam.k1 *. r2 <= 0. {
      None
    } else {
      let factor = 1. +. cam.k1 *. r2
      Some((xn *. factor *. fx +. lcx, yn *. factor *. fy +. lcy))
    }
  }
}

// A court segment as warped-pixel polylines (split where points leave the
// model's valid range), shifted by `offset` into the native frame.
let lensPolylines = (
  cam: DinkHunt.kioskCamera,
  ~offset: (float, float),
  (wa, wb): ((float, float), (float, float)),
): array<array<(float, float)>> => {
  let samples = 40
  let (ox, oy) = offset
  let ((ax, ay), (bx, by)) = (wa, wb)
  let runs = []
  let current = ref([])
  for i in 0 to samples {
    let f = Int.toFloat(i) /. Int.toFloat(samples)
    switch lensProject(cam, (ax +. (bx -. ax) *. f, ay +. (by -. ay) *. f)) {
    | Some((x, y)) => current.contents->Array.push((x +. ox, y +. oy))
    | None =>
      if current.contents->Array.length >= 2 {
        runs->Array.push(current.contents)
      }
      current := []
    }
  }
  if current.contents->Array.length >= 2 {
    runs->Array.push(current.contents)
  }
  runs
}

// Which un-anchored handles would help the lens estimate most: ones the user
// can actually see (inside the frame, clear of the edges — a clipped corner
// dragged to the edge is wrong data), farthest from the frame centre, where
// a wide lens bends lines the most.
let lensSuggestions = (
  fit: courtFit,
  placed: array<placedAnchor>,
  ~nativeW: float,
  ~nativeH: float,
): array<string> => {
  let missing = lensAnchorsNeeded - placed->Array.length
  if fit.stage != Perspective || missing <= 0 {
    []
  } else {
    let margin = 0.04
    anchors
    ->Array.filterMap(((name, _)) =>
      if placed->Array.some(a => a.name == name) {
        None
      } else {
        handlePosition(fit, placed, name)->Option.flatMap(((x, y)) => {
          let (u, v) = (x /. nativeW, y /. nativeH)
          if u < margin || u > 1. -. margin || v < margin || v > 1. -. margin {
            None
          } else {
            let (du, dv) = (u -. 0.5, (v -. 0.5) *. nativeH /. nativeW)
            Some((name, du *. du +. dv *. dv))
          }
        })
      }
    )
    ->Array.toSorted(((_, a), (_, b)) => b -. a)
    ->Array.slice(~start=0, ~end=missing)
    ->Array.map(((name, _)) => name)
  }
}

type status = Idle | Saving | Failed(string)

// The live lens preview (the server's non-saving solve of the current
// anchors), tagged with the payload it was solved from.
type previewOutcome =
  | Solved(DinkHunt.kioskCamera, string) // camera, server message
  | Rejected(string) // the server refused these anchors
  | Unavailable(string) // server down / too old / no camera
type preview = {key: string, offset: (float, float), outcome: previewOutcome}

// `toolbarHost` is where the instructions + Confirm/Reset/Skip render (via a
// portal): the page row ABOVE the video, so no control ever sits over the
// frame being calibrated. None renders no toolbar (the host mounts in the
// same commit, so that is only ever a pre-paint instant).
@react.component
let make = (
  ~stream: option<UserMedia.t>,
  ~toolbarHost: option<Dom.element>,
  ~onDone: unit => unit,
) => {
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

  // The staged fit (see courtFit): the court stays put until the anchors
  // actually determine it.
  let courtState = courtFit(placed, ~nativeW, ~nativeH)
  let fit = courtState.h

  // ── Live lens preview ──────────────────────────────────────────────────────
  // Once the full fit exists, each settled drag asks the analysis server to
  // solve pose + lens (without saving) and reprojects the court through the
  // result — the bent lines are the visual proof the correction fits.
  let payload = solvePayload(placed, ~nativeW=nativeW->Float.toInt, ~nativeH=nativeH->Float.toInt)
  let currentKey = payloadKey(payload)
  let (preview, setPreview) = React.useState(() => (None: option<preview>))
  let (previewPending, setPreviewPending) = React.useState(() => false)
  let isDragging = dragging->Option.isSome
  let wantsPreview = courtState.stage == Perspective && !isDragging
  React.useEffect3(() => {
    let upToDate = preview->Option.mapOr(false, p => p.key == currentKey)
    if wantsPreview && !upToDate {
      let cancelled = ref(false)
      setPreviewPending(_ => true)
      let requested = payload
      let key = currentKey
      // Debounced: settle on the anchors before spending a ~0.3 s solve.
      let timer = setTimeout(() => {
        let run = async () => {
          let outcome = switch await DinkHunt.previewKioskCourt(
            ~width=requested.width,
            ~height=requested.height,
            ~corners=requested.corners,
          ) {
          | Ok(result) =>
            switch (result.ok, result.camera->Option.flatMap(Nullable.toOption)) {
            | (true, Some(camera)) => Solved(camera, result.message)
            | (true, None) => Unavailable("the analysis server sent no camera")
            | (false, _) => Rejected(result.message)
            }
          | Error(message) =>
            Unavailable(
              String.includes(message, "Cannot query field")
                ? "restart the analysis server to enable it"
                : message,
            )
          }
          if !cancelled.contents {
            setPreview(_ => Some({key, offset: requested.offset, outcome}))
            setPreviewPending(_ => false)
          }
        }
        run()->ignore
      }, 350)
      Some(
        () => {
          cancelled := true
          clearTimeout(timer)
          setPreviewPending(_ => false)
        },
      )
    } else {
      None
    }
  }, (currentKey, wantsPreview, courtState.stage))

  // The lens camera, only while it matches the anchors on screen.
  let lens = switch preview {
  | Some({key, offset, outcome: Solved(camera, _)}) if key == currentKey && !isDragging =>
    Some((camera, offset))
  | _ => None
  }
  let lensPoint = (name: string) =>
    lens->Option.flatMap(((camera, (ox, oy))) =>
      lensProject(camera, worldOf(name))->Option.map(((x, y)) => (x +. ox, y +. oy))
    )
  // Anchored handles sit where the user put them; inferred ones follow the
  // lens-corrected reprojection when there is one, else the straight fit.
  let positionOf = (name: string) =>
    switch (lens, placed->Array.some(a => a.name == name)) {
    | (Some(_), false) => lensPoint(name)
    | _ => handlePosition(courtState, placed, name)
    }
  // Court lines as polylines: lens-corrected curves when available.
  let courtPolylines = () =>
    switch lens {
    | Some((camera, offset)) =>
      segments->Array.flatMap(segment => lensPolylines(camera, ~offset, segment))
    | None =>
      segments->Array.filterMap(((wa, wb)) =>
        projectSegment(fit, wa, wb)->Option.map(((pa, pb)) => [pa, pb])
      )
    }
  let suggested = lensSuggestions(courtState, placed, ~nativeW, ~nativeH)

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
      // The same payload the live preview solves (see solvePayload).
      let {width, height, corners} = payload
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
            // The fitted court lines through this neighbourhood — only once
            // there IS a fit; the default court's lines would just mislead.
            // Lens-corrected curves when the preview has them (drawn solid —
            // they are what the analysis will use), else the straight fit.
            if courtState.stage != Unfitted {
              ctx->setStrokeStyle("rgba(190, 242, 100, 0.8)")
              ctx->setLineWidth(1. *. dpr)
              ctx->setLineDash(lens->Option.isSome ? [] : [4. *. dpr, 4. *. dpr])
              courtPolylines()->Array.forEach(polyline =>
                polyline->Array.forEachWithIndex((point, i) =>
                  if i > 0 {
                    let (x1, y1) = toLoupe(polyline->Array.getUnsafe(i - 1))
                    let (x2, y2) = toLoupe(point)
                    line(x1, y1, x2, y2)
                  }
                )
              )
              ctx->setLineDash([])
            }
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
  // handle is selected (placed/zoom/preview in the deps keep the closure
  // current — a lens preview arriving swaps in the corrected lines).
  let loupeTarget = selected->Option.flatMap(name => positionOf(name)->Option.map(p => (name, p)))
  React.useEffect5(() => {
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
  }, (selected, zoom, placed, preview, isDragging))

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
    courtState.stage == Perspective &&
      anchors->Array.some(((name, w)) =>
        String.includes(name, "baseline") &&
        !(placed->Array.some(a => a.name == name)) &&
        projectVisible(fit, w) == None
      )

  let (stageLabel, hint) = switch courtState.stage {
  | Unfitted => (
      "NO FIT · " ++ anchored->Int.toString ++ " ANCHORED",
      "Drag points onto their painted marks — only the points you move will move. " ++
      "The court follows once 3 of them are not on one court line.",
    )
  | Affine => (
      "ROUGH FIT",
      "Anchor one more point (no 3 on one line) for the full perspective fit.",
    )
  | Perspective => (
      switch lens {
      | Some((camera, _)) if camera.k1 != 0. => "FULL FIT · LENS CORRECTED"
      | _ => "FULL FIT"
      },
      "Drag any point to refine. Use the kitchen (NK/FK) points when the baselines are out of frame.",
    )
  }
  // Lens guidance + feedback, once the full fit exists: how many more anchors
  // the lens estimate needs, then what the server's preview solve found.
  let lensStatus: option<(string, string)> = if courtState.stage != Perspective {
    None
  } else {
    let need = lensAnchorsNeeded - anchored
    let latest = preview->Option.flatMap(p => p.key == currentKey ? Some(p.outcome) : None)
    let fitPx = (camera: DinkHunt.kioskCamera) => Float.toFixed(camera.rmsPx, ~digits=1) ++ " px"
    Some(
      switch (need > 0, isDragging || previewPending, latest) {
      | (true, _, _) => (
          "text-amber-300",
          "Lens correction needs " ++
          lensAnchorsNeeded->Int.toString ++
          " anchors (" ++
          anchored->Int.toString ++
          " so far): anchor " ++
          need->Int.toString ++
          " more. The amber +LENS points, near the frame edges where the lens bends lines most, help most.",
        )
      | (false, true, _) | (false, false, None) => ("text-kiosk-muted", "Lens: solving…")
      | (false, false, Some(Solved(camera, _))) if camera.k1 != 0. => (
          "text-kiosk-accent",
          "Lens corrected (k1 " ++
          Float.toFixed(camera.k1, ~digits=3) ++
          ", fit " ++
          fitPx(camera) ++ "). Solid lines are the corrected court; dashed white is the uncorrected fit.",
        )
      | (false, false, Some(Solved(camera, _))) => (
          "text-kiosk-muted",
          "Lens: no correction applied — the straight-line fit is within drag noise, " ++
          "or correcting didn't improve it enough (fit " ++
          fitPx(camera) ++ ").",
        )
      | (false, false, Some(Rejected(message))) => ("text-amber-300", "Lens preview: " ++ message)
      | (false, false, Some(Unavailable(message))) => (
          "text-kiosk-muted",
          "Lens preview unavailable — " ++ message ++ ".",
        )
      },
    )
  }
  let toolbar =
    <div
      className="flex flex-wrap items-center gap-x-4 gap-y-2 border-2 border-kiosk-border bg-kiosk-surface px-4 py-2">
      <div className="min-w-0 flex-1">
        <p className="flex flex-wrap items-baseline gap-x-3">
          <span className="font-extrabold text-white"> {React.string("Court setup")} </span>
          <span
            className={"font-mono text-xs font-semibold " ++ (
              courtState.stage == Perspective ? "text-kiosk-accent" : "text-amber-300"
            )}>
            {React.string(stageLabel)}
          </span>
        </p>
        // FIXED-HEIGHT text slots: this toolbar sits above the video, so any
        // change in its height moves (and rescales) the frame — measured 20 px
        // mid-drag when the lens line swapped two lines for one, putting the
        // handle 17 px off under the finger. Hint and message each keep two
        // lines whatever they say; the message slot shows the most urgent of
        // save failure > unstable fit > lens status.
        <p className="line-clamp-2 min-h-[2.5rem] text-sm text-kiosk-muted" title=hint>
          {React.string(hint)}
        </p>
        {
          let (tone, message) = switch (saveStatus, unstable, lensStatus) {
          | (Failed(message), _, _) => ("text-red-300", message)
          | (_, true, _) => (
              "text-amber-300",
              "Fit is unstable — a baseline projects beyond the horizon. " ++
              "Anchor any baseline corners you can see (FAR L/R or NEAR L/R).",
            )
          | (_, false, Some((tone, text))) => (tone, text)
          | (_, false, None) => ("text-kiosk-muted", "")
          }
          <p
            className={"mt-1 line-clamp-2 min-h-[2.5rem] text-sm font-semibold " ++ tone}
            title=message>
            {React.string(message)}
          </p>
        }
      </div>
      <div className="flex shrink-0 gap-2">
        <button
          type_="button"
          disabled={saveStatus == Saving || courtState.stage != Perspective}
          onClick={_ => confirm()}
          // Fixed width: its label changes as points are placed, and a width
          // change would re-wrap the text beside it (see the slots above).
          className="flex min-h-12 w-[19rem] items-center justify-center border-2 border-kiosk-accent bg-kiosk-accent px-3 font-extrabold text-kiosk-bg transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-accentDark disabled:opacity-50">
          <span className="truncate">
            {React.string(
              saveStatus == Saving
                ? "Solving pose…"
                : courtState.stage == Perspective
                ? "Confirm court (" ++ anchored->Int.toString ++ " anchored)"
                : anchored < 4
                ? "Anchor " ++ (4 - anchored)->Int.toString ++ " more"
                : "Need 4 not on one line",
            )}
          </span>
        </button>
        <button
          type_="button"
          onClick={_ => setPlaced(_ => [])}
          className="flex min-h-12 items-center justify-center border-2 border-kiosk-border bg-kiosk-raised px-4 font-extrabold text-white active:bg-kiosk-border">
          {React.string("Reset")}
        </button>
        <button
          type_="button"
          onClick={_ => onDone()}
          className="flex min-h-12 items-center justify-center border-2 border-kiosk-border bg-kiosk-raised px-4 font-extrabold text-white active:bg-kiosk-border">
          {React.string("Skip")}
        </button>
      </div>
    </div>

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
      // Court wireframe, projected through the live fit. This SVG spans the
      // whole container, letterbox bars included, so the lines sit in a nested
      // viewport the size of the video frame, which clips what runs past it.
      <svg x="0" y="0" width={fmt(nativeW)} height={fmt(nativeH)} overflow="hidden">
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
              stroke={lens->Option.isSome ? "#ffffff" : "#bef264"}
              strokeWidth={lens->Option.isSome ? "2" : "3"}
              // Faint dashed guide while nothing is fitted (it is just the
              // default court); dashed while rough (affine); solid when full.
              // Once the lens-corrected court is drawn below, this straight
              // fit stays as a faint white reference: where the two part
              // (toward the frame edges) is the lens correction at work.
              strokeOpacity={switch (lens, courtState.stage) {
              | (Some(_), _) => "0.4"
              | (None, Unfitted) => "0.3"
              | (None, Affine) => "0.6"
              | (None, Perspective) => "0.8"
              }}
              strokeDasharray={lens->Option.isSome
                ? "10 10"
                : courtState.stage == Perspective
                ? ""
                : "14 10"}
            />
          | None => React.null
          }
        )
        ->React.array}
        {switch lens {
        | Some(_) =>
          courtPolylines()
          ->Array.mapWithIndex((polyline, index) =>
            <polyline
              key={"lens" ++ index->Int.toString}
              points={polyline
              ->Array.map(((x, y)) => fmt(x) ++ "," ++ fmt(y))
              ->Array.join(" ")}
              fill="none"
              stroke="#bef264"
              strokeWidth="3.5"
              strokeOpacity="0.95"
              strokeLinejoin="round"
            />
          )
          ->React.array
        | None => React.null
        }}
      </svg>
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
            let isSuggested = suggested->Array.includes(name)
            <g key=name opacity={isPlaced ? "1" : "0.8"}>
              // Lens guidance: a pulsing amber ring on the visible points that
              // would help the lens estimate most (see lensSuggestions).
              {isSuggested
                ? <circle
                    cx={fmt(x)}
                    cy={fmt(y)}
                    r={fmt(ringR +. 10. /. sc)}
                    fill="none"
                    stroke="#fbbf24"
                    strokeWidth={fmt(strokeW *. 1.5)}
                    strokeDasharray={fmt(4. /. sc)}
                    className="pointer-events-none animate-pulse"
                  />
                : React.null}
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
                fill={isPlaced ? "#ffffff" : isSuggested ? "#fbbf24" : "#d9f99d"}
                stroke="#000000"
                strokeWidth={fmt(3. /. sc)}
                paintOrder="stroke"
                fontSize={fmt(13. /. sc)}
                fontWeight="800"
                fontFamily="monospace"
                className="pointer-events-none select-none">
                {React.string(anchorLabel(name) ++ (isSuggested ? " +LENS" : ""))}
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
    // The toolbar lives OUTSIDE the video (see toolbarHost) so it never
    // covers the landmarks. Portals still bubble React events to this root,
    // which only uses them to end drags — harmless.
    {switch toolbarHost {
    | Some(host) => ReactDOM.createPortal(toolbar, host)
    | None => React.null
    }}
  </div>
}
