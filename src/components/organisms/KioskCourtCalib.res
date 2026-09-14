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
      switch await DinkHunt.setKioskCourt(
        ~width=nativeW->Float.toInt,
        ~height=nativeH->Float.toInt,
        ~corners,
      ) {
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

  let fmt = Float.toString
  let anchored = placed->Array.length
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
    <svg
      className="absolute inset-0 h-full w-full"
      viewBox={"0 0 " ++ fmt(nativeW) ++ " " ++ fmt(nativeH)}
      preserveAspectRatio="xMidYMid meet">
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
      // Handles: anchored solid, un-anchored hollow (they ride the fit).
      {anchors
      ->Array.map(((name, _)) =>
        switch positionOf(name) {
        | None => React.null
        | Some((x, y)) => {
        let isPlaced = placed->Array.some(a => a.name == name)
        <g key=name>
          <circle
            cx={fmt(x)}
            cy={fmt(y)}
            r="30"
            fill={isPlaced ? "rgba(190, 242, 100, 0.30)" : "rgba(0, 0, 0, 0.25)"}
            stroke="#bef264"
            strokeWidth={isPlaced ? "5" : "2"}
            strokeDasharray={isPlaced ? "" : "6 6"}
            className="cursor-grab"
            onPointerDown={event => {
              ReactEvent.Pointer.preventDefault(event)
              setDragging(_ => Some(name))
            }}
          />
          <text
            x={fmt(x)}
            y={fmt(y -. 42.)}
            textAnchor="middle"
            fill="#bef264"
            fillOpacity={isPlaced ? "1" : "0.6"}
            fontSize="26"
            fontWeight="800"
            fontFamily="monospace">
            {React.string(anchorLabel(name))}
          </text>
        </g>
        }
        }
      )
      ->React.array}
    </svg>
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
