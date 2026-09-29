%%raw("import { t } from '@lingui/macro'")
open Util

// Camera kiosk UI, converted from the Magic Patterns "COURTSIDE.AI" design.
//
// The kiosk runs full screen on a courtside touch device and has two session
// categories:
// - Live game: rolling capture with mid-game actions (clip last rally,
//   Challenge — bounce detection over the buffer via the dinkhunt analysis
//   server) and optional YouTube streaming with a viewer QR code.
// - Analysis: pick a mode (drop shot placement, serve speed), capture, then
//   end the session to view the result.
//
// Real today: the camera feed, the rolling-buffer clip extraction
// (lib/capture), the Challenge flow (DinkHunt.res -> localhost analysis
// server), and court calibration (KioskCourtCalib). Still mock shells:
// analysis results and YouTube streaming — marked with TODO(kiosk).

type category = Live | Analysis
type liveAction = RallyClip | Challenge
type analysisMode = DropShot | ServeSpeed
type resultMode = LiveResult(liveAction) | AnalysisResult(analysisMode)
type stage = Ready | Active | Processing | Result
type notice = ClipSaved | LiveEnded | CameraError | ClipFailed | ClipDownloaded | TestClipMissing

// A muxed rally clip held as an object URL for playback + download. Clips are
// auto-saved into a per-session history; URLs are released when a clip is
// deleted, evicted, or the session ends.
type clipState = {
  url: string,
  durationSeconds: float,
  hasAudio: bool,
  capturedAt: string, // "HH:MM" label for the history strip
  frameTimes: array<float>, // real per-frame timestamps (s); empty = unknown
}

// A Challenge run: the buffered clip plus the dinkhunt shot-finder's ground
// bounces over it (times are clip-relative, so they map straight onto the
// player timeline). ``error`` keeps the clip reviewable even when analysis
// failed (server down, camera not calibrated).
type challengeState = {
  clip: clipState,
  bounces: array<DinkHunt.bounce>,
  // Overlay data (empty when analysis failed): per-shot ball paths in clip
  // pixels + the clip's native frame size the pixel space refers to.
  paths: array<array<DinkHunt.pathPoint>>,
  frameW: int,
  frameH: int,
  fps: float,
  error: option<string>,
}

// How much of the rolling buffer a Challenge analyzes. Analysis cost is
// per-FRAME (decode + detector; BlurBall resizes to 512x288 internally, so
// clip resolution barely matters) — 8s of 60fps is ~480 frames against the
// full ring's ~1200. Long enough to carry the shots either side of a bounce,
// which is what the shot-finder needs to classify it.
let challengeSeconds = 8.

// Results come back in the pixel space of the clip the server analysed. When
// that clip was cropped to the court's analysis region, shift them back into
// the full frame the Challenge player overlays.
let reprojectAnalysis = (
  a: DinkHunt.challengeAnalysis,
  crop: option<ClipCrop.rect>,
): DinkHunt.challengeAnalysis =>
  switch crop {
  | None => a
  | Some(r) => {
      let dx = Int.toFloat(r.x)
      let dy = Int.toFloat(r.y)
      let shift = (p: array<float>) =>
        switch (p->Array.get(0), p->Array.get(1)) {
        | (Some(x), Some(y)) => [x +. dx, y +. dy]
        | _ => p
        }
      {
        ...a,
        bounces: a.bounces->Array.map(b => {
          ...b,
          pixel: shift(b.pixel),
          footprint: b.footprint->Array.map(shift),
        }),
        paths: a.paths->Array.map(path =>
          path->Array.map((pt: DinkHunt.pathPoint) => {...pt, x: pt.x +. dx, y: pt.y +. dy})
        ),
      }
    }
  }

// Bounded so a long session cannot accumulate unbounded blob memory.
let maxClipHistory = 5

// Delay revocation: a download may still be streaming this blob.
let releaseClip = (clip: clipState) => {
  let _ = setTimeout(() => CaptureSession.revokeObjectURL(clip.url), 60_000)
}

let timeLabel = () => {
  let now = Date.make()
  let hours = now->Date.getHours->Int.toString->String.padStart(2, "0")
  let minutes = now->Date.getMinutes->Int.toString->String.padStart(2, "0")
  hours ++ ":" ++ minutes
}

// TODO(kiosk): real per-court stream URL once YouTube streaming is wired up.
let liveStreamUrl = "https://youtube.com/live/courtside-court04"

// The chosen camera persists across reloads so a provisioned kiosk keeps
// using the same device. Only touched from handlers/effects (no SSR access).
let cameraStorageKey = "kiosk.cameraDeviceId"

// Test mode: no camera needed — sessions start without a stream and the
// Challenge action runs against the server's fixed test_challenge.mov.
let testModeStorageKey = "kiosk.testMode"

@val @scope("localStorage") external getStoredItem: string => Nullable.t<string> = "getItem"
@val @scope("localStorage") external setStoredItem: (string, string) => unit = "setItem"
@val @scope("localStorage") external removeStoredItem: string => unit = "removeItem"

open Lingui.Util

let liveActionKey = action =>
  switch action {
  | RallyClip => "rally-clip"
  | Challenge => "challenge"
  }

let liveActionName = action =>
  switch action {
  | RallyClip => t`Clip last rally`
  | Challenge => t`Challenge`
  }

let liveActionDescription = action =>
  switch action {
  | RallyClip => t`Create a clean, shareable clip from the rolling video buffer.`
  | Challenge => t`Overlay detected bounces on the buffered footage and replay any of them.`
  }

let analysisModeKey = mode =>
  switch mode {
  | DropShot => "drop-shot"
  | ServeSpeed => "serve-speed"
  }

let analysisModeName = mode =>
  switch mode {
  | DropShot => t`Drop shot analysis`
  | ServeSpeed => t`Serve speed analysis`
  }

let analysisModeDescription = mode =>
  switch mode {
  | DropShot => t`Track drop-shot placement and reveal landing patterns.`
  | ServeSpeed => t`Measure serve speed and review the detected serve clip.`
  }

let analysisModeHelper = mode =>
  switch mode {
  | DropShot => t`End the session when you have collected enough shots.`
  | ServeSpeed => t`Capture several serves, then end to view the result.`
  }

module ModeCard = {
  @react.component
  let make = (~mode: analysisMode, ~selected: bool, ~onSelect: analysisMode => unit) => {
    let icon = switch mode {
    | DropShot => <Lucide.Target \"aria-hidden"="true" size=30 strokeWidth=2.2 />
    | ServeSpeed => <Lucide.Activity \"aria-hidden"="true" size=30 strokeWidth=2.2 />
    }
    <button
      type_="button"
      onClick={_ => onSelect(mode)}
      ariaPressed={selected ? #"true" : #"false"}
      className={cx([
        "flex min-h-32 w-full items-center gap-5 border-2 p-5 text-left transition-[background-color,border-color,transform] duration-150 ease-out active:translate-y-1",
        selected
          ? "border-kiosk-accent bg-kiosk-accent text-kiosk-bg"
          : "border-kiosk-border bg-kiosk-surface text-white active:bg-kiosk-raised",
      ])}>
      <span
        className={cx([
          "flex h-16 w-16 shrink-0 items-center justify-center border-2",
          selected ? "border-kiosk-bg/30" : "border-kiosk-border bg-kiosk-raised",
        ])}>
        icon
      </span>
      <span className="min-w-0">
        <span className="block text-xl font-extrabold leading-tight"> {analysisModeName(mode)} </span>
        <span
          className={cx([
            "mt-2 block text-sm leading-5",
            selected ? "text-kiosk-bg/70" : "text-kiosk-muted",
          ])}>
          {analysisModeDescription(mode)}
        </span>
      </span>
    </button>
  }
}

module CameraView = {
  @react.component
  let make = (
    ~sessionLabel: React.element,
    ~streamingEnabled: bool,
    ~elapsed: int,
    ~stream: option<UserMedia.t>,
    // Off when other controls float over the bottom of the view (a live
    // session's action cards and status row), which this label would show
    // through.
    ~showSessionInfo: bool=true,
    // Off during court calibration: the corner badges sit exactly where the
    // far court corners and the loupe go.
    ~showBadges: bool=true,
  ) => {
    let videoRef = React.useRef(Nullable.null)

    // Attach the live camera stream to the <video> element.
    React.useEffect1(() => {
      switch videoRef.current->Nullable.toOption {
      | Some(video) =>
        video->UserMedia.setSrcObject(
          switch stream {
          | Some(stream) => Nullable.make(stream)
          | None => Nullable.null
          },
        )
      | None => ()
      }
      None
    }, [stream])

    let minutes = (elapsed / 60)->Int.toString->String.padStart(2, "0")
    let seconds = (elapsed->mod(60))->Int.toString->String.padStart(2, "0")

    <div
      className={cx([
        // Fills whatever area the session layout gives it (no min-height, so
        // it can never push the control cluster off screen); object-contain
        // letterboxes any camera aspect against black instead of cropping.
        "relative h-full w-full overflow-hidden border-2 border-kiosk-border",
        stream->Option.isSome ? "bg-black" : "bg-kiosk-court min-h-[330px]",
      ])}>
      {switch stream {
      | Some(_) =>
        <video
          ref={ReactDOM.Ref.domRef(videoRef)}
          autoPlay=true
          muted=true
          playsInline=true
          className="absolute inset-0 h-full w-full object-contain"
        />
      | None =>
        // Placeholder court render for when no camera feed is available.
        <>
          <div className="absolute inset-x-[8%] bottom-[-10%] top-[19%] [perspective:600px]">
            <div
              className="relative h-full w-full [transform:rotateX(58deg)] border-[3px] border-white/70 bg-kiosk-courtLight">
              <span className="absolute inset-y-0 left-1/2 w-[2px] -translate-x-1/2 bg-white/65" />
              <span className="absolute inset-x-0 top-1/2 h-[2px] -translate-y-1/2 bg-white/65" />
              <span className="absolute inset-y-0 left-1/4 w-[2px] bg-white/45" />
              <span className="absolute inset-y-0 right-1/4 w-[2px] bg-white/45" />
            </div>
          </div>
          <div className="absolute left-[18%] top-[41%] h-16 w-7 rounded-full bg-kiosk-bg/80 shadow-xl" />
          <div className="absolute right-[20%] top-[35%] h-20 w-8 rounded-full bg-kiosk-bg/80 shadow-xl" />
          <div
            className="absolute right-[34%] top-[57%] h-3 w-3 rounded-full bg-kiosk-accent shadow-[0_0_0_4px_rgba(198,255,61,0.18)]"
          />
        </>
      }}
      {showBadges
        ? <div className="absolute inset-x-0 top-0 flex items-center justify-between p-4 sm:p-5">
            <div
              className="flex min-h-12 items-center gap-2 border border-white/20 bg-kiosk-bg/90 px-4 font-mono text-xs font-semibold text-white backdrop-blur-sm">
              <Lucide.Camera \"aria-hidden"="true" size=16 />
              {React.string("COURT CAM 01")}
            </div>
            <div
              className={cx([
                "flex min-h-12 items-center gap-2 border px-4 font-mono text-xs font-semibold",
                streamingEnabled
                  ? "border-red-300 bg-red-500 text-white"
                  : "border-white/20 bg-kiosk-bg/90 text-white",
              ])}>
              {streamingEnabled
                ? <Lucide.Radio \"aria-hidden"="true" size=15 />
                : <Lucide.Circle \"aria-hidden"="true" className="fill-red-500 text-red-500" size=10 />}
              {React.string(
                (streamingEnabled ? "LIVE" : "REC") ++ " · " ++ minutes ++ ":" ++ seconds,
              )}
            </div>
          </div>
        : React.null}
      {showSessionInfo
        ? <div
            className="absolute bottom-4 left-4 right-4 flex items-end justify-between sm:bottom-5 sm:left-5 sm:right-5">
            <div className="border-l-4 border-kiosk-accent bg-kiosk-bg/90 px-4 py-3 backdrop-blur-sm">
              <p className="text-xs font-medium text-kiosk-muted"> {t`ACTIVE SESSION`} </p>
              <p className="mt-0.5 font-bold text-white"> sessionLabel </p>
            </div>
            <div
              className="hidden border border-white/20 bg-kiosk-bg/90 px-3 py-2 text-xs text-white/80 sm:block">
              {React.string("1080p · 60 FPS")}
            </div>
          </div>
        : React.null}
    </div>
  }
}

module VideoMock = {
  // TODO(kiosk): replace with a real clip player once clips exist.
  @react.component
  let make = (~label: React.element, ~playLabel: string) => {
    <div className="relative aspect-video overflow-hidden border-2 border-kiosk-border bg-kiosk-court">
      <span className="absolute inset-y-[12%] left-1/2 w-0.5 bg-white/50" />
      <span className="absolute inset-x-[10%] top-1/2 h-0.5 bg-white/50" />
      <button
        type_="button"
        ariaLabel=playLabel
        className="absolute left-1/2 top-1/2 flex h-20 w-20 -translate-x-1/2 -translate-y-1/2 items-center justify-center border-4 border-white bg-kiosk-bg/90 text-white transition-[background-color,transform] duration-150 ease-out active:-translate-y-[46%] active:bg-kiosk-accent active:text-kiosk-bg">
        <Lucide.Play \"aria-hidden"="true" className="ml-1 fill-current" size=31 />
      </button>
      <span
        className="absolute bottom-3 left-3 border border-white/30 bg-kiosk-bg/90 px-3 py-2 text-xs font-semibold text-white">
        label
      </span>
    </div>
  }
}

module ClipPlayer = {
  // Plays a real muxed clip from its object URL (native controls; the badge
  // sits top-left so it stays clear of them).
  @react.component
  let make = (~clip: clipState) => {
    <div className="relative aspect-video overflow-hidden border-2 border-kiosk-border bg-black">
      <video
        src=clip.url
        controls=true
        playsInline=true
        autoPlay=true
        muted=true
        className="absolute inset-0 h-full w-full object-contain"
      />
      <span
        className="pointer-events-none absolute left-3 top-3 border border-white/30 bg-kiosk-bg/90 px-3 py-2 text-xs font-semibold text-white">
        {React.string(clip.durationSeconds->Float.toFixed(~digits=0) ++ " s")}
        {clip.hasAudio
          ? React.null
          : <>
              {React.string(" · ")}
              {t`no audio`}
            </>}
      </span>
    </div>
  }
}

module ChallengePlayer = {
  // The Challenge review: the buffered clip with the shot-finder's ground
  // bounces marked on a timeline strip. Tapping a marker seeks just ahead of
  // the impact and plays; ½× keeps the replay readable on a kiosk screen.
  @send external play: Dom.element => promise<unit> = "play"
  @set external setCurrentTime: (Dom.element, float) => unit = "currentTime"
  @set external setPlaybackRate: (Dom.element, float) => unit = "playbackRate"
  @get external currentTime: Dom.element => float = "currentTime"
  @send external pause: Dom.element => unit = "pause"
  @get external isPaused: Dom.element => bool = "paused"
  @val external requestAnimationFrame: (float => unit) => int = "requestAnimationFrame"
  @val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"

  type domRect = {width: float, height: float}
  @send external getBoundingClientRect: Dom.element => domRect = "getBoundingClientRect"

  let zoomFactor = 2.6

  // CSS transform that magnifies around a clip-space point: map the point's
  // letterboxed display position to the container centre under scale(k).
  // Applied to a wrapper holding BOTH the video and the overlay SVG, so the
  // drawn arcs/markers stay glued to the pixels at any zoom.
  let zoomTransformFor = (
    rect: domRect,
    frameW: float,
    frameH: float,
    (px, py): (float, float),
  ): string => {
    let scale = Math.min(rect.width /. frameW, rect.height /. frameH)
    let ox = (rect.width -. frameW *. scale) /. 2.
    let oy = (rect.height -. frameH *. scale) /. 2.
    let dx = ox +. px *. scale // the bounce's display position, container coords
    let dy = oy +. py *. scale
    let tx = rect.width /. 2. -. dx *. zoomFactor
    let ty = rect.height /. 2. -. dy *. zoomFactor
    "translate(" ++
    tx->Float.toFixed(~digits=1) ++
    "px, " ++
    ty->Float.toFixed(~digits=1) ++
    "px) scale(" ++
    zoomFactor->Float.toString ++
    ")"
  }

  // The ball's overlay position at time ``t``: the path segment containing
  // ``t``, linearly interpolated (paths are 30Hz samples of the fitted arcs,
  // so lerp error is sub-pixel).
  let ballAt = (paths: array<array<DinkHunt.pathPoint>>, t: float): option<(float, float)> =>
    paths
    ->Array.find(path =>
      switch (path->Array.get(0), path->Array.get(path->Array.length - 1)) {
      | (Some(first), Some(last)) => first.t <= t && t <= last.t
      | _ => false
      }
    )
    ->Option.flatMap(path => {
      let index = ref(0)
      while (
        index.contents < path->Array.length - 2 &&
          (path->Array.getUnsafe(index.contents + 1)).t < t
      ) {
        index := index.contents + 1
      }
      switch (path->Array.get(index.contents), path->Array.get(index.contents + 1)) {
      | (Some(a), Some(b)) => {
          let span = b.t -. a.t
          let f = span <= 0. ? 0. : (t -. a.t) /. span
          Some((a.x +. (b.x -. a.x) *. f, a.y +. (b.y -. a.y) *. f))
        }
      | _ => None
      }
    })

  @react.component
  let make = (~challenge: challengeState) => {
    let videoRef = React.useRef(Nullable.null)
    let (selected, setSelected) = React.useState(() => (None: option<int>))
    let (slow, setSlow) = React.useState(() => true)
    let (overlayOn, setOverlayOn) = React.useState(() => true)
    let (now, setNow) = React.useState(() => 0.)
    // Impact loop: replay a +/-6-frame window around the selected bounce on
    // repeat. The window lives in a REF because the rAF tick below runs in a
    // once-mounted closure and must always see the current target.
    let (looping, setLooping) = React.useState(() => false)
    let (zoomed, setZoomed) = React.useState(() => false)
    let (playing, setPlaying) = React.useState(() => false)
    let (zoomTransform, setZoomTransform) = React.useState(() => (None: option<string>))
    let playerRef = React.useRef(Nullable.null)
    let loopWindow = React.useRef((None: option<(float, float)>))
    let duration = Math.max(challenge.clip.durationSeconds, 0.1)
    let loopHalf = 6. /. Math.max(challenge.fps, 1.)
    // Bounces/paths are in analysis time (frame / fps); the video plays on
    // its real capture timeline. All seeks, marker reveals and the riding
    // ball go through this mapping so they stay on the actual frame.
    let timeline = FrameTimeline.make(~frameTimes=challenge.clip.frameTimes, ~fps=challenge.fps)
    let toVideo = t => timeline->FrameTimeline.toVideo(t)

    // Track playback time at display rate for the overlay (timeupdate fires
    // only ~4Hz — too coarse for a riding ball marker).
    React.useEffect1(() => {
      let handle = ref(None)
      let rec tick = _ => {
        switch videoRef.current->Nullable.toOption {
        | Some(el) => {
            let t = el->currentTime
            switch loopWindow.current {
            | Some((start, stop)) if t > stop && !(el->isPaused) =>
              el->setCurrentTime(start)
            | _ => ()
            }
            setNow(previous => Math.abs(previous -. t) > 0.005 ? t : previous)
          }
        | None => ()
        }
        handle := Some(requestAnimationFrame(tick))
      }
      handle := Some(requestAnimationFrame(tick))
      Some(
        () =>
          switch handle.contents {
          | Some(id) => cancelAnimationFrame(id)
          | None => ()
          },
      )
    }, [])

    let retargetZoom = (bounce: DinkHunt.bounce) =>
      switch playerRef.current->Nullable.toOption {
      | Some(el) => {
          let x = bounce.pixel->Array.get(0)->Option.getOr(0.)
          let y = bounce.pixel->Array.get(1)->Option.getOr(0.)
          setZoomTransform(_ => Some(
            zoomTransformFor(
              getBoundingClientRect(el),
              challenge.frameW->Int.toFloat,
              challenge.frameH->Int.toFloat,
              (x, y),
            ),
          ))
        }
      | None => ()
      }

    let startLoop = (bounce: DinkHunt.bounce) => {
      let start = Math.max(0., toVideo(bounce.t -. loopHalf))
      loopWindow.current = Some((start, Math.min(duration, toVideo(bounce.t +. loopHalf))))
      setLooping(_ => true)
      if zoomed {
        retargetZoom(bounce)
      }
      switch videoRef.current->Nullable.toOption {
      | Some(element) => {
          element->setPlaybackRate(slow ? 0.5 : 1.0)
          element->setCurrentTime(start)
          element->play->ignore
        }
      | None => ()
      }
    }

    let stopLoop = () => {
      loopWindow.current = None
      setLooping(_ => false)
      setZoomTransform(_ => None)
    }

    let toggleZoom = () => {
      let next = !zoomed
      setZoomed(_ => next)
      if next {
        switch selected->Option.flatMap(i => challenge.bounces->Array.get(i)) {
        | Some(bounce) if looping => retargetZoom(bounce)
        | _ => ()
        }
      } else {
        setZoomTransform(_ => None)
      }
    }

    let replayBounce = (index: int, bounce: DinkHunt.bounce) => {
      setSelected(_ => Some(index))
      if looping {
        startLoop(bounce) // retarget the loop to the newly picked bounce
      } else {
        switch videoRef.current->Nullable.toOption {
        | Some(element) => {
            element->setPlaybackRate(slow ? 0.5 : 1.0)
            element->setCurrentTime(Math.max(0., toVideo(bounce.t) -. 0.75))
            element->play->ignore
          }
        | None => ()
        }
      }
    }

    let stepBy = (frames: int) =>
      switch videoRef.current->Nullable.toOption {
      | Some(el) => {
          el->pause
          // Lands exactly on a real frame's timestamp, not a uniform 1/fps hop.
          el->setCurrentTime(
            Math.max(0., Math.min(duration, timeline->FrameTimeline.stepFrames(el->currentTime, frames))),
          )
        }
      | None => ()
      }
    let togglePlay = () =>
      switch videoRef.current->Nullable.toOption {
      | Some(el) =>
        if el->isPaused {
          el->setPlaybackRate(slow ? 0.5 : 1.0)
          el->play->ignore
        } else {
          el->pause
        }
      | None => ()
      }

    <div>
      <div
        ref={ReactDOM.Ref.domRef(playerRef)}
        className="relative aspect-video overflow-hidden border-2 border-kiosk-border bg-black">
        <div
          className="absolute inset-0 origin-top-left will-change-transform"
          style={switch zoomTransform {
          | Some(transform) => ReactDOM.Style.make(~transform, ())
          | None => ReactDOM.Style.make()
          }}>
        <video
          ref={ReactDOM.Ref.domRef(videoRef)}
          src=challenge.clip.url
          controls={zoomTransform == None}
          playsInline=true
          muted=true
          onPlay={_ => setPlaying(_ => true)}
          onPause={_ => setPlaying(_ => false)}
          className="absolute inset-0 h-full w-full object-contain"
        />
        // analyze.py-style overlay: shot paths, bounce ground marks (appear
        // at their moment of impact), and the ball marker riding the fitted
        // arcs. viewBox = clip pixels; aligns with the object-contain video
        // because both letterbox the same aspect into the same box.
        {overlayOn && challenge.paths->Array.length > 0
          ? <svg
              className="pointer-events-none absolute inset-0 h-full w-full"
              viewBox={"0 0 " ++
              challenge.frameW->Int.toString ++
              " " ++
              challenge.frameH->Int.toString}
              preserveAspectRatio="xMidYMid meet">
              {
                // Highlight the ball WITHOUT painting over it: the frame is
                // dimmed slightly except for a soft spotlight on the ball, a
                // hollow ring sits OUTSIDE it, and the trail is cut where it
                // crosses it — the real ball pixels are never covered.
                let fw = challenge.frameW->Int.toFloat
                let fh = challenge.frameH->Int.toFloat
                let unit = Math.max(1., fw /. 1280.) // stroke widths scale with the clip
                let ringR = Math.max(12., fw *. 0.012) // clear of a ~74mm ball at any zoom
                let spotR = ringR *. 3.
                let ball = ballAt(challenge.paths, timeline->FrameTimeline.toAnalysis(now))
                let fmt = Float.toString
                let fullRect = fill => <rect x="0" y="0" width={fmt(fw)} height={fmt(fh)} fill />
                <>
                  <defs>
                    <radialGradient id="kiosk-ball-spot-grad">
                      <stop offset="0%" stopColor="#000000" />
                      <stop offset="50%" stopColor="#000000" />
                      <stop offset="100%" stopColor="#ffffff" />
                    </radialGradient>
                    <mask
                      id="kiosk-ball-spot"
                      maskUnits="userSpaceOnUse"
                      x="0"
                      y="0"
                      width={fmt(fw)}
                      height={fmt(fh)}>
                      {fullRect("#ffffff")}
                      {switch ball {
                      | Some((x, y)) =>
                        <circle cx={fmt(x)} cy={fmt(y)} r={fmt(spotR)} fill="url(#kiosk-ball-spot-grad)" />
                      | None => React.null
                      }}
                    </mask>
                    <mask
                      id="kiosk-ball-clear"
                      maskUnits="userSpaceOnUse"
                      x="0"
                      y="0"
                      width={fmt(fw)}
                      height={fmt(fh)}>
                      {fullRect("#ffffff")}
                      {switch ball {
                      | Some((x, y)) => <circle cx={fmt(x)} cy={fmt(y)} r={fmt(ringR)} fill="#000000" />
                      | None => React.null
                      }}
                    </mask>
                  </defs>
                  // Spotlight: everything but the ball's neighbourhood dims a
                  // little while the ball is being tracked.
                  <rect
                    x="0"
                    y="0"
                    width={fmt(fw)}
                    height={fmt(fh)}
                    fill="#000000"
                    opacity={ball->Option.isSome ? "0.35" : "0"}
                    mask="url(#kiosk-ball-spot)"
                    className="transition-opacity duration-200"
                  />
                  <g mask="url(#kiosk-ball-clear)">
                    {challenge.paths
                    ->Array.mapWithIndex((path, index) =>
                      <polyline
                        key={index->Int.toString}
                        points={path
                        ->Array.map(pt => pt.x->Float.toString ++ "," ++ pt.y->Float.toString)
                        ->Array.join(" ")}
                        fill="none"
                        stroke="#bef264"
                        strokeWidth={fmt(3. *. unit)}
                        strokeOpacity="0.55"
                      />
                    )
                    ->React.array}
                  </g>
                  {challenge.bounces
                  ->Array.mapWithIndex((bounce, index) =>
                    toVideo(bounce.t) <= now
                      ? {
                          let x = bounce.pixel->Array.get(0)->Option.getOr(0.)
                          let y = bounce.pixel->Array.get(1)->Option.getOr(0.)
                          let colour = selected == Some(index) ? "#ffffff" : "#4ade80"
                          // Label BELOW the ground mark: at the moment of
                          // impact the ball sits right on the contact pixel,
                          // and a label above it would cover the ball.
                          let footBottom =
                            bounce.footprint->Array.reduce(y, (acc, pt) =>
                              Math.max(acc, pt->Array.get(1)->Option.getOr(y))
                            )
                          let labelY = Math.max(footBottom, y +. 10. *. unit) +. 26. *. unit
                          <g key={index->Int.toString}>
                            {// The perspective-correct marker: the server projects a ground
                            // disc at the contact, so the ring foreshortens with depth.
                            bounce.footprint->Array.length >= 3
                              ? <polygon
                                  points={bounce.footprint
                                  ->Array.map(p =>
                                    p->Array.get(0)->Option.getOr(x)->Float.toString ++
                                    "," ++
                                    p->Array.get(1)->Option.getOr(y)->Float.toString
                                  )
                                  ->Array.join(" ")}
                                  fill="none"
                                  stroke=colour
                                  strokeWidth={fmt(3. *. unit)}
                                  strokeLinejoin="round"
                                />
                              : <ellipse
                                  cx={fmt(x)}
                                  cy={fmt(y)}
                                  rx={fmt(26. *. unit)}
                                  ry={fmt(10. *. unit)}
                                  fill="none"
                                  stroke=colour
                                  strokeWidth={fmt(3. *. unit)}
                                />}
                            <text
                              x={fmt(x)}
                              y={fmt(labelY)}
                              textAnchor="middle"
                              fill=colour
                              stroke="#000000"
                              strokeWidth={fmt(4. *. unit)}
                              paintOrder="stroke"
                              fontSize={fmt(22. *. unit)}
                              fontWeight="800"
                              fontFamily="monospace">
                              {React.string("bounce " ++ (index + 1)->Int.toString)}
                            </text>
                          </g>
                        }
                      : React.null
                  )
                  ->React.array}
                  // The ball ring: hollow and wider than the ball, with a dark
                  // halo so it reads on light court paint and bright walls.
                  {switch ball {
                  | Some((x, y)) =>
                    <g>
                      <circle
                        cx={fmt(x)}
                        cy={fmt(y)}
                        r={fmt(ringR)}
                        fill="none"
                        stroke="#000000"
                        strokeOpacity="0.55"
                        strokeWidth={fmt(5. *. unit)}
                      />
                      <circle
                        cx={fmt(x)}
                        cy={fmt(y)}
                        r={fmt(ringR)}
                        fill="none"
                        stroke="#fde047"
                        strokeWidth={fmt(2.5 *. unit)}
                      />
                    </g>
                  | None => React.null
                  }}
                </>
              }
            </svg>
          : React.null}
        </div>
      </div>
      // Transport: pause + single-frame stepping. Deliberately OUTSIDE every
      // mode — stepping works while looping (a paused loop does not wrap),
      // zoomed, or with the overlay off. Frame readout uses the clip's fps.
      <div className="mt-3 flex items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <button
            type_="button"
            ariaLabel="back one frame"
            onClick={_ => stepBy(-1)}
            className="flex min-h-12 min-w-14 items-center justify-center border-2 border-kiosk-border bg-kiosk-raised font-extrabold text-white active:bg-kiosk-border">
            <Lucide.ChevronLeft \"aria-hidden"="true" size=20 />
            {React.string("1f")}
          </button>
          <button
            type_="button"
            ariaLabel={playing ? "pause" : "play"}
            onClick={_ => togglePlay()}
            className="flex min-h-12 min-w-16 items-center justify-center border-2 border-kiosk-accent bg-kiosk-accent px-4 font-extrabold text-kiosk-bg active:bg-kiosk-accentDark">
            {playing ? <Lucide.Square \"aria-hidden"="true" className="fill-current" size=16 /> : <Lucide.Play \"aria-hidden"="true" className="fill-current" size=16 />}
          </button>
          <button
            type_="button"
            ariaLabel="forward one frame"
            onClick={_ => stepBy(1)}
            className="flex min-h-12 min-w-14 items-center justify-center border-2 border-kiosk-border bg-kiosk-raised font-extrabold text-white active:bg-kiosk-border">
            {React.string("1f")}
            <Lucide.ChevronRight \"aria-hidden"="true" size=20 />
          </button>
        </div>
        <p className="font-mono text-xs font-semibold text-kiosk-muted">
          {React.string(
            "f " ++
            timeline->FrameTimeline.frameIndexAt(now)->Int.toString ++
            " · " ++
            now->Float.toFixed(~digits=2) ++ "s",
          )}
        </p>
      </div>
      {switch challenge.error {
      | Some(message) =>
        <p
          className="mt-3 border-2 border-red-400/40 bg-red-500/10 px-4 py-3 text-sm font-semibold text-red-300">
          {React.string(message)}
        </p>
      | None => React.null
      }}
      {challenge.bounces->Array.length == 0 && challenge.error == None
        ? <p className="mt-3 text-sm text-kiosk-muted">
            {t`No ground bounces were detected in the buffered footage.`}
          </p>
        : React.null}
      {challenge.bounces->Array.length > 0
        ? <>
            // Timeline strip: one marker per bounce at its clip-relative time.
            <div className="relative mt-4 h-14 border-2 border-kiosk-border bg-kiosk-raised">
              {challenge.bounces
              ->Array.mapWithIndex((bounce, index) =>
                <button
                  key={index->Int.toString}
                  type_="button"
                  onClick={_ => replayBounce(index, bounce)}
                  ariaLabel={"bounce " ++ (index + 1)->Int.toString}
                  style={ReactDOM.Style.make(
                    ~left=(toVideo(bounce.t) /. duration *. 100.)->Float.toFixed(~digits=1) ++ "%",
                    (),
                  )}
                  className={cx([
                    "absolute top-1/2 flex h-9 w-9 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full border-2 text-xs font-extrabold transition-transform active:scale-90",
                    selected == Some(index)
                      ? "border-kiosk-accent bg-kiosk-accent text-kiosk-bg"
                      : "border-white/60 bg-kiosk-bg text-white",
                  ])}>
                  {React.string((index + 1)->Int.toString)}
                </button>
              )
              ->React.array}
            </div>
            // Chip row: one large target per bounce (markers on the strip
            // can overlap when impacts land within a second of each other).
            <div className="mt-3 flex items-center gap-2 overflow-x-auto pb-1">
              {challenge.bounces
              ->Array.mapWithIndex((bounce, index) =>
                <button
                  key={index->Int.toString}
                  type_="button"
                  onClick={_ => replayBounce(index, bounce)}
                  className={cx([
                    "flex min-h-12 shrink-0 items-center gap-2 whitespace-nowrap border-2 px-4 font-mono text-sm font-extrabold transition-[background-color,transform] duration-150 ease-out active:translate-y-1",
                    selected == Some(index)
                      ? "border-kiosk-accent bg-kiosk-accent text-kiosk-bg"
                      : "border-kiosk-border bg-kiosk-raised text-white active:bg-kiosk-border",
                  ])}>
                  <span> {React.string("#" ++ (index + 1)->Int.toString)} </span>
                  <span className="opacity-70">
                    {React.string(toVideo(bounce.t)->Float.toFixed(~digits=1) ++ "s")}
                  </span>
                </button>
              )
              ->React.array}
            </div>
            <div className="mt-2 flex items-center justify-between gap-3">
              <p className="text-sm text-kiosk-muted">
                {t`${challenge.bounces->Array.length->Int.toString} bounces detected · tap one to replay`}
              </p>
              <div className="flex items-center gap-2">
                <button
                  type_="button"
                  disabled={selected == None}
                  onClick={_ =>
                    looping
                      ? stopLoop()
                      : switch selected->Option.flatMap(i => challenge.bounces->Array.get(i)) {
                        | Some(bounce) => startLoop(bounce)
                        | None => ()
                        }}
                  className={cx([
                    "border-2 px-4 py-2 text-sm font-extrabold disabled:opacity-40",
                    looping
                      ? "border-kiosk-accent bg-kiosk-accent text-kiosk-bg"
                      : "border-kiosk-border bg-kiosk-raised text-white",
                  ])}>
                  {React.string(looping ? "Looping" : "Loop " ++ `±` ++ "6f")}
                </button>
                <button
                  type_="button"
                  disabled={!looping}
                  onClick={_ => toggleZoom()}
                  className={cx([
                    "border-2 px-4 py-2 text-sm font-extrabold disabled:opacity-40",
                    zoomed && looping
                      ? "border-kiosk-accent bg-kiosk-accent text-kiosk-bg"
                      : "border-kiosk-border bg-kiosk-raised text-white",
                  ])}>
                  {t`Zoom`}
                </button>
                <button
                  type_="button"
                  onClick={_ => setOverlayOn(value => !value)}
                  className={cx([
                    "border-2 px-4 py-2 text-sm font-extrabold",
                    overlayOn
                      ? "border-kiosk-accent bg-kiosk-accent text-kiosk-bg"
                      : "border-kiosk-border bg-kiosk-raised text-white",
                  ])}>
                  {t`Overlay`}
                </button>
                <button
                  type_="button"
                  onClick={_ => setSlow(value => !value)}
                  className={cx([
                    "border-2 px-4 py-2 text-sm font-extrabold",
                    slow
                      ? "border-kiosk-accent bg-kiosk-accent text-kiosk-bg"
                      : "border-kiosk-border bg-kiosk-raised text-white",
                  ])}>
                  {React.string(slow ? "0.5x" : "1x")}
                </button>
              </div>
            </div>
          </>
        : React.null}
    </div>
  }
}

module DoneButton = {
  @react.component
  let make = (~onClick: unit => unit) => {
    <button
      type_="button"
      onClick={_ => onClick()}
      className="mt-5 flex min-h-20 w-full items-center justify-center gap-3 border-2 border-kiosk-accent bg-kiosk-accent px-5 text-lg font-extrabold text-kiosk-bg transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-accentDark">
      <Lucide.RotateCcw \"aria-hidden"="true" size=23 />
      {t`Start another session`}
    </button>
  }
}

module ResultShell = {
  @react.component
  let make = (
    ~title: React.element,
    ~subtitle: React.element,
    ~eyebrow: option<React.element>=?,
    ~children: React.element,
  ) => {
    let eyebrow = eyebrow->Option.getOr(t`ANALYSIS COMPLETE`)
    <section
      ariaLive=#polite
      className="mx-auto w-full max-w-3xl border-2 border-kiosk-border bg-kiosk-surface p-5 sm:p-8">
      <p className="font-mono text-sm font-semibold text-kiosk-accent"> eyebrow </p>
      <h2 className="mt-2 text-3xl font-extrabold text-white sm:text-4xl"> title </h2>
      <p className="mt-2 text-base text-kiosk-muted"> subtitle </p>
      <div className="mt-6"> children </div>
    </section>
  }
}

@val @scope(("navigator", "clipboard"))
external writeText: string => promise<unit> = "writeText"

module LiveStreamShare = {
  @react.component
  let make = () => {
    let (copied, setCopied) = React.useState(() => false)

    React.useEffect1(() => {
      if copied {
        let timer = setTimeout(() => setCopied(_ => false), 2000)
        Some(() => clearTimeout(timer))
      } else {
        None
      }
    }, [copied])

    let copyUrl = async () => {
      try {
        await writeText(liveStreamUrl)
        setCopied(_ => true)
      } catch {
      | _ => setCopied(_ => false)
      }
    }

    <aside
      className="flex h-full min-h-0 flex-col overflow-y-auto border-2 border-kiosk-border bg-kiosk-surface p-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <div className="flex items-center gap-2 text-red-400">
            <Lucide.Youtube \"aria-hidden"="true" size=20 />
            <span className="text-sm font-semibold"> {React.string("YouTube Live")} </span>
          </div>
          <h2 className="mt-2 text-xl font-bold text-white"> {t`Scan to watch`} </h2>
        </div>
        <span
          className="flex h-14 w-14 shrink-0 items-center justify-center border-2 border-kiosk-border bg-kiosk-raised text-kiosk-accent">
          <Lucide.QrCode \"aria-hidden"="true" size=25 />
        </span>
      </div>
      <p className="mt-2 text-sm leading-5 text-kiosk-muted">
        {t`Point a phone camera at the code to open this court's live stream.`}
      </p>
      <div className="mx-auto my-5 border-4 border-white bg-white p-2">
        <QRCode value=liveStreamUrl size={Some(184)} />
      </div>
      <div className="mt-auto">
        <p className="text-xs font-medium text-kiosk-muted"> {t`VIEWING URL`} </p>
        <p className="mt-1 truncate font-mono text-xs text-white" title=liveStreamUrl>
          {React.string(liveStreamUrl)}
        </p>
        <div className="mt-4 grid grid-cols-2 gap-2">
          <button
            type_="button"
            onClick={_ => copyUrl()->ignore}
            className="flex min-h-16 items-center justify-center gap-2 whitespace-nowrap border-2 border-kiosk-border bg-kiosk-raised px-3 text-sm font-bold text-white transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-border">
            {copied
              ? <Lucide.Check \"aria-hidden"="true" className="text-kiosk-accent" size=19 />
              : <Lucide.Copy \"aria-hidden"="true" size=19 />}
            {copied ? t`Copied` : t`Copy URL`}
          </button>
          <a
            href=liveStreamUrl
            target="_blank"
            rel="noreferrer"
            className="flex min-h-16 items-center justify-center gap-2 whitespace-nowrap border-2 border-white bg-white px-3 text-sm font-extrabold text-kiosk-bg transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-white/80">
            {t`Open`}
            <Lucide.ExternalLink \"aria-hidden"="true" size=18 />
          </a>
        </div>
      </div>
    </aside>
  }
}

module SettingsPanel = {
  @react.component
  let make = (
    ~cameras: array<UserMedia.deviceInfo>,
    ~selectedCameraId: option<string>,
    ~onSelect: option<string> => unit,
    ~captureMode: CaptureSession.mode,
    ~onSelectMode: CaptureSession.mode => unit,
    ~testMode: bool,
    ~onToggleTestMode: unit => unit,
    ~onClose: unit => unit,
  ) => {
    let optionClass = selected =>
      cx([
        "flex min-h-20 w-full items-center gap-4 border-2 px-5 text-left transition-[background-color,border-color,transform] duration-150 ease-out active:translate-y-1",
        selected
          ? "border-kiosk-accent bg-kiosk-accent text-kiosk-bg"
          : "border-kiosk-border bg-kiosk-raised text-white active:bg-kiosk-border",
      ])
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-kiosk-bg/80 p-4 backdrop-blur-sm"
      onClick={_ => onClose()}>
      <div
        role="dialog"
        className="max-h-full w-full max-w-lg overflow-y-auto border-2 border-kiosk-border bg-kiosk-surface p-5 sm:p-6"
        onClick={event => event->ReactEvent.Mouse.stopPropagation}>
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="font-mono text-sm font-semibold text-kiosk-muted"> {t`KIOSK SETTINGS`} </p>
            <h2 className="mt-1 text-2xl font-extrabold text-white"> {t`Camera source`} </h2>
          </div>
          <button
            type_="button"
            ariaLabel={Lingui.UtilString.t`Close settings`}
            onClick={_ => onClose()}
            className="flex h-14 w-14 shrink-0 items-center justify-center border-2 border-kiosk-border bg-kiosk-raised text-kiosk-muted transition-[background-color,color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-border active:text-white">
            <Lucide.X \"aria-hidden"="true" size=24 />
          </button>
        </div>
        <p className="mt-2 text-sm text-kiosk-muted">
          {t`Choose which connected camera the kiosk uses. The change applies immediately, including to a running session.`}
        </p>
        <div className="mt-5 grid gap-3">
          <button
            type_="button"
            ariaPressed={selectedCameraId == None ? #"true" : #"false"}
            onClick={_ => onSelect(None)}
            className={optionClass(selectedCameraId == None)}>
            <span
              className={cx([
                "flex h-12 w-12 shrink-0 items-center justify-center border-2",
                selectedCameraId == None ? "border-kiosk-bg/30" : "border-kiosk-border",
              ])}>
              <Lucide.RefreshCw \"aria-hidden"="true" size=22 />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block font-extrabold leading-tight"> {t`System default camera`} </span>
              <span className={selectedCameraId == None ? "mt-1 block text-sm text-kiosk-bg/70" : "mt-1 block text-sm text-kiosk-muted"}>
                {t`Let the browser pick the default device`}
              </span>
            </span>
            {selectedCameraId == None
              ? <Lucide.Check \"aria-hidden"="true" className="shrink-0" size=24 />
              : React.null}
          </button>
          {cameras
          ->Array.mapWithIndex((device, index) => {
            let selected = selectedCameraId == Some(device.deviceId)
            <button
              key=device.deviceId
              type_="button"
              ariaPressed={selected ? #"true" : #"false"}
              onClick={_ => onSelect(Some(device.deviceId))}
              className={optionClass(selected)}>
              <span
                className={cx([
                  "flex h-12 w-12 shrink-0 items-center justify-center border-2",
                  selected ? "border-kiosk-bg/30" : "border-kiosk-border",
                ])}>
                <Lucide.Camera \"aria-hidden"="true" size=22 />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block truncate font-extrabold leading-tight">
                  {device.label == ""
                    ? t`Camera ${(index + 1)->Int.toString}`
                    : React.string(device.label)}
                </span>
              </span>
              {selected
                ? <Lucide.Check \"aria-hidden"="true" className="shrink-0" size=24 />
                : React.null}
            </button>
          })
          ->React.array}
        </div>
        {cameras->Array.length == 0
          ? <p className="mt-4 border-l-4 border-kiosk-accent bg-kiosk-accent/10 p-4 text-sm text-kiosk-muted">
              {t`No cameras detected. Connect a camera or allow camera access, then reopen settings.`}
            </p>
          : React.null}
        <div className="mt-8">
          <p className="font-mono text-sm font-semibold text-kiosk-muted"> {t`PROCESSING MODE`} </p>
          <div className="mt-3 grid gap-3">
            <button
              type_="button"
              ariaPressed={captureMode == CaptureSession.LocalRing ? #"true" : #"false"}
              onClick={_ => onSelectMode(CaptureSession.LocalRing)}
              className={optionClass(captureMode == CaptureSession.LocalRing)}>
              <span
                className={cx([
                  "flex h-12 w-12 shrink-0 items-center justify-center border-2",
                  captureMode == CaptureSession.LocalRing ? "border-kiosk-bg/30" : "border-kiosk-border",
                ])}>
                <Lucide.History \"aria-hidden"="true" size=22 />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block font-extrabold leading-tight"> {t`Local`} </span>
                <span
                  className={captureMode == CaptureSession.LocalRing
                    ? "mt-1 block text-sm text-kiosk-bg/70"
                    : "mt-1 block text-sm text-kiosk-muted"}>
                  {t`On-device rolling buffer and clip processing`}
                </span>
              </span>
              {captureMode == CaptureSession.LocalRing
                ? <Lucide.Check \"aria-hidden"="true" className="shrink-0" size=24 />
                : React.null}
            </button>
            // TODO(kiosk): enable once ThinClientCapture is implemented.
            <button
              type_="button"
              disabled=true
              className={cx([optionClass(false), "cursor-not-allowed opacity-40 active:translate-y-0"])}>
              <span className="flex h-12 w-12 shrink-0 items-center justify-center border-2 border-kiosk-border">
                <Lucide.Wifi \"aria-hidden"="true" size=22 />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block font-extrabold leading-tight">
                  {t`Thin client`}
                  <span className="ml-2 border border-current px-2 py-0.5 align-middle font-mono text-[10px] font-bold">
                    {t`COMING SOON`}
                  </span>
                </span>
                <span className="mt-1 block text-sm text-kiosk-muted">
                  {t`Stream to the server for processing`}
                </span>
              </span>
            </button>
            <button
              type_="button"
              ariaPressed={testMode ? #"true" : #"false"}
              onClick={_ => onToggleTestMode()}
              className={optionClass(testMode)}>
              <span
                className={cx([
                  "flex h-12 w-12 shrink-0 items-center justify-center border-2",
                  testMode ? "border-kiosk-bg/30" : "border-kiosk-border",
                ])}>
                <Lucide.Dices \"aria-hidden"="true" size=22 />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block font-extrabold leading-tight"> {t`Test mode`} </span>
                <span
                  className={cx([
                    "mt-1 block text-sm",
                    testMode ? "text-kiosk-bg/70" : "text-kiosk-muted",
                  ])}>
                  {t`No camera: Challenge runs on the server's fixed test clip.`}
                </span>
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
  }
}

module LiveActionControls = {
  @react.component
  let make = (
    ~onAction: liveAction => unit,
    ~bufferStatus: option<CaptureSession.status>,
    ~clipEnabled: bool,
    ~clipping: bool,
    ~testMode: bool,
    ~clips: array<clipState>,
    ~onReview: clipState => unit,
  ) => {
    // Rendered INSIDE the camera overlay (bottom of the video, over a scrim):
    // no box of its own, compact rows, so the video keeps the screen.
    <section>
      <div className="flex flex-col justify-between gap-2 sm:flex-row sm:items-end">
        <div>
          <h2 className="text-lg font-extrabold text-white"> {t`Choose an action`} </h2>
        </div>
        <p
          className={cx([
            "font-mono text-xs font-semibold",
            bufferStatus->Option.isSome ? "text-kiosk-accent" : "text-kiosk-muted",
          ])}>
          {switch bufferStatus {
          | None => t`CLIPPING UNAVAILABLE`
          | Some(status) =>
            status.bufferedSeconds >= status.targetSeconds
              ? t`● BUFFER READY`
              : t`● BUFFER ${status.bufferedSeconds->Float.toFixed(~digits=0)}s / ${status.targetSeconds
                  ->Float.toFixed(~digits=0)}s`
          }}
        </p>
      </div>
      <div className="mt-3 grid gap-3 sm:grid-cols-2">
        {[RallyClip, Challenge]
        ->Array.map(action => {
          let icon = switch action {
          | RallyClip => <Lucide.Scissors \"aria-hidden"="true" size=31 strokeWidth=2.4 />
          | Challenge => <Lucide.Target \"aria-hidden"="true" size=31 strokeWidth=2.4 />
          }
          let disabled = switch action {
          | RallyClip => !clipEnabled || clipping
          // Test mode swaps the buffer for the server's fixed clip.
          | Challenge => (!clipEnabled && !testMode) || clipping
          }
          <button
            key={liveActionKey(action)}
            type_="button"
            disabled
            onClick={_ => onAction(action)}
            className={cx([
              "flex min-h-20 items-center gap-4 border-2 px-4 text-left transition-[background-color,transform] duration-150 ease-out active:translate-y-1",
              action == RallyClip
                ? "border-kiosk-accent bg-kiosk-accent text-kiosk-bg active:bg-kiosk-accentDark"
                : "border-white bg-white text-kiosk-bg active:bg-white/80",
              disabled ? "cursor-not-allowed opacity-40 active:translate-y-0" : "",
            ])}>
            <span className="flex h-12 w-12 shrink-0 items-center justify-center border-2 border-kiosk-bg/30">
              icon
            </span>
            <span>
              <span className="block text-lg font-extrabold leading-tight"> {liveActionName(action)} </span>
              <span className="mt-1 block text-xs font-medium leading-4 opacity-70">
                {action == RallyClip && clipping ? t`Clipping…` : t`Use latest buffered footage`}
              </span>
            </span>
          </button>
        })
        ->React.array}
      </div>
      {clips->Array.length == 0
        ? React.null
        : <div className="mt-3 flex items-center gap-3 overflow-x-auto">
            <p className="shrink-0 font-mono text-xs font-semibold text-kiosk-muted">
              {t`RECENT CLIPS`}
            </p>
            {clips
            ->Array.map(clip =>
              <button
                key=clip.url
                type_="button"
                onClick={_ => onReview(clip)}
                className="flex min-h-14 shrink-0 items-center gap-2 whitespace-nowrap border-2 border-kiosk-border bg-kiosk-raised px-4 font-mono text-sm font-semibold text-white transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-border">
                <Lucide.Play \"aria-hidden"="true" className="fill-current text-kiosk-accent" size=16 />
                {React.string(
                  clip.durationSeconds->Float.toFixed(~digits=0) ++ " s · " ++ clip.capturedAt,
                )}
              </button>
            )
            ->React.array}
          </div>}
    </section>
  }
}

module ResultPanel = {
  @react.component
  let make = (
    ~modeId: resultMode,
    ~clip: option<clipState>,
    ~challenge: option<challengeState>,
    ~onDone: unit => unit,
    ~onSaved: unit => unit,
    ~onDelete: unit => unit,
    ~isLiveSession: bool,
  ) => {
    let eyebrow = isLiveSession ? Some(t`ROLLING BUFFER CAPTURE`) : None

    // TODO(kiosk): apart from the rally clip, the result content below is
    // mock data awaiting its real pipeline.
    switch modeId {
    | LiveResult(RallyClip) =>
      // Review of an auto-saved clip from the history strip. The clip is
      // already kept; Save is an optional local download, Delete removes it
      // from the history, Done returns to the live view.
      switch clip {
      | Some(clip) =>
        <ResultShell
          title={t`Rally clip`}
          subtitle={t`${clip.durationSeconds->Float.toFixed(
              ~digits=0,
            )}-second clip · ${clip.capturedAt}`}
          ?eyebrow>
          <ClipPlayer clip />
          <div className="mt-5 grid gap-3 sm:grid-cols-3">
            <button
              type_="button"
              onClick={_ => onDelete()}
              className="flex min-h-20 items-center justify-center gap-3 border-2 border-kiosk-border bg-kiosk-raised px-5 text-lg font-extrabold text-white transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-red-500/15">
              <Lucide.Trash2 \"aria-hidden"="true" size=23 />
              {t`Delete clip`}
            </button>
            // TODO(kiosk): upload the clip to the server (instead of or as
            // well as this local download) once a backend endpoint exists.
            <a
              href=clip.url
              download={"courtside-rally-" ++ Date.now()->Float.toString ++ ".mp4"}
              onClick={_ => onSaved()}
              className="flex min-h-20 items-center justify-center gap-3 border-2 border-white bg-white px-5 text-lg font-extrabold text-kiosk-bg transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-white/80">
              <Lucide.Download \"aria-hidden"="true" size=23 />
              {t`Save clip`}
            </a>
            <button
              type_="button"
              onClick={_ => onDone()}
              className="flex min-h-20 items-center justify-center gap-3 border-2 border-kiosk-accent bg-kiosk-accent px-5 text-lg font-extrabold text-kiosk-bg transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-accentDark">
              <Lucide.Check \"aria-hidden"="true" size=23 />
              {t`Done`}
            </button>
          </div>
        </ResultShell>
      | None =>
        // Defensive fallback: the review screen is only reachable from a
        // history entry, so this mock should not normally show.
        <ResultShell title={t`Rally clip`} subtitle={t`No clip selected`} ?eyebrow>
          <VideoMock label={t`Last rally`} playLabel={Lingui.UtilString.t`Play last rally`} />
          <DoneButton onClick=onDone />
        </ResultShell>
      }
    | LiveResult(Challenge) =>
      switch challenge {
      | Some(challenge) =>
        <ResultShell
          title={t`Challenge`}
          subtitle={t`${challenge.clip.durationSeconds->Float.toFixed(
              ~digits=0,
            )}-second buffer · ${challenge.clip.capturedAt}`}
          ?eyebrow>
          <ChallengePlayer challenge />
          <DoneButton onClick=onDone />
        </ResultShell>
      | None =>
        // Analysis still in flight or takeClip failed; the Processing screen
        // normally covers this — defensive fallback only.
        <ResultShell title={t`Challenge`} subtitle={t`No footage analyzed`} ?eyebrow>
          <VideoMock label={t`Challenge`} playLabel={Lingui.UtilString.t`Play challenge`} />
          <DoneButton onClick=onDone />
        </ResultShell>
      }
    | AnalysisResult(DropShot) =>
      <ResultShell title={t`Drop shot placement`} subtitle={t`24 shots analyzed · Game session`}>
        <div className="relative aspect-[1.45] overflow-hidden border-2 border-white/60 bg-kiosk-court">
          <span className="absolute inset-y-0 left-1/2 w-0.5 bg-white/60" />
          <span className="absolute inset-x-0 top-1/2 h-0.5 bg-white/60" />
          <span
            className="absolute left-[18%] top-[62%] h-20 w-20 rounded-full border-[12px] border-red-400/35 bg-red-400/30"
          />
          <span className="absolute left-[26%] top-[68%] h-11 w-11 rounded-full bg-red-400/75" />
          <span
            className="absolute right-[20%] top-[56%] h-24 w-24 rounded-full border-[14px] border-amber-300/30 bg-amber-300/25"
          />
          <span className="absolute right-[28%] top-[65%] h-12 w-12 rounded-full bg-amber-300/70" />
          <span className="absolute left-[45%] top-[71%] h-7 w-7 rounded-full bg-kiosk-accent/70" />
          <div className="absolute left-3 top-3 rounded-lg bg-kiosk-bg/85 px-3 py-2 text-xs font-semibold text-white">
            {t`LANDING HEATMAP`}
          </div>
        </div>
        <div className="mt-4 grid grid-cols-2 divide-x-2 divide-kiosk-border border-2 border-kiosk-border bg-kiosk-raised">
          <div className="p-5">
            <p className="text-sm text-kiosk-muted"> {t`Kitchen accuracy`} </p>
            <p className="mt-1 text-3xl font-extrabold text-white"> {React.string("79%")} </p>
          </div>
          <div className="p-5">
            <p className="text-sm text-kiosk-muted"> {t`Best target`} </p>
            <p className="mt-1 text-3xl font-extrabold text-white"> {t`Backhand`} </p>
          </div>
        </div>
        <DoneButton onClick=onDone />
      </ResultShell>
    | AnalysisResult(ServeSpeed) =>
      <ResultShell title={t`Serve detected`} subtitle={t`Serve 04 · Clean read`}>
        <VideoMock label={t`Serve replay`} playLabel={Lingui.UtilString.t`Play serve replay`} />
        <div className="mt-4 flex items-end justify-between border-2 border-kiosk-accent/40 bg-kiosk-accent/10 p-6">
          <div>
            <p className="text-sm font-medium text-kiosk-muted"> {t`Peak ball speed`} </p>
            <p className="mt-1 font-mono text-6xl font-semibold text-white"> {React.string("42.8")} </p>
          </div>
          <p className="pb-1 font-mono text-xl font-semibold text-kiosk-accent"> {React.string("MPH")} </p>
        </div>
        <DoneButton onClick=onDone />
      </ResultShell>
    }
  }
}

module SessionWorkspace = {
  @react.component
  let make = (
    ~category: category,
    ~analysisMode: analysisMode,
    ~resultMode: resultMode,
    ~stage: stage,
    ~elapsed: int,
    ~streamingEnabled: bool,
    ~stream: option<UserMedia.t>,
    ~reviewClip: option<clipState>,
    ~challenge: option<challengeState>,
    ~calibOpen: bool,
    // Where the calibration toolbar renders: the row above the video.
    ~calibToolbarHost: option<Dom.element>,
    ~onCalibDone: unit => unit,
    ~onCalibOpen: unit => unit,
    ~testMode: bool,
    ~clips: array<clipState>,
    ~clipping: bool,
    ~bufferStatus: option<CaptureSession.status>,
    ~clipEnabled: bool,
    ~onLiveAction: liveAction => unit,
    ~onReviewClip: clipState => unit,
    ~onDeleteClip: unit => unit,
    ~onFinishAnalysis: unit => unit,
    ~onEndLive: unit => unit,
    ~onResultDone: unit => unit,
    ~onSaved: unit => unit,
  ) => {
    let isLiveSession = category == Live

    switch stage {
    | Ready => React.null
    | Processing =>
      <section
        ariaLive=#polite
        className="flex min-h-[560px] flex-col items-center justify-center border-2 border-kiosk-border bg-kiosk-surface px-6 text-center">
        {isLiveSession
          ? <p className="mb-5 border-2 border-red-400/40 bg-red-500/15 px-4 py-3 font-mono text-xs font-semibold text-red-300">
              {t`LIVE SESSION CONTINUES · BUFFER RECORDING`}
            </p>
          : React.null}
        <Lucide.Loader2 \"aria-hidden"="true" className="animate-spin text-kiosk-accent" size=52 />
        <h2 className="mt-6 text-3xl font-bold text-white"> {t`Analyzing the play`} </h2>
        <p className="mt-2 max-w-md text-kiosk-muted">
          {t`Finding the clearest camera moments and preparing your result.`}
        </p>
        <div className="mt-7 h-1.5 w-full max-w-xs overflow-hidden rounded-full bg-kiosk-border">
          <div className="h-full w-3/4 rounded-full bg-kiosk-accent" />
        </div>
      </section>
    | Result =>
      <div>
        {isLiveSession
          ? <div
              className="mx-auto mb-4 flex min-h-16 w-full max-w-3xl items-center gap-3 border-2 border-red-400/40 bg-red-500/10 px-5">
              <span className="h-3 w-3 bg-red-500" />
              <p className="text-sm font-bold text-white">
                {t`Live session and rolling buffer are still active`}
              </p>
            </div>
          : React.null}
        <ResultPanel
          modeId=resultMode
          clip=reviewClip
          challenge
          onDone=onResultDone
          onSaved
          onDelete=onDeleteClip
          isLiveSession
        />
      </div>
    | Active => {
        let sessionLabel = isLiveSession ? t`Rolling buffer` : analysisModeName(analysisMode)
        <section className="flex min-h-0 flex-1 flex-col">
          <div
            className={cx([
              // The video area takes all remaining height; the control
              // cluster below hugs the bottom of the screen.
              "min-h-0 flex-1",
              isLiveSession && streamingEnabled
                ? "grid grid-rows-[minmax(0,1fr)_auto] gap-4 lg:grid-cols-[minmax(0,1fr)_320px] lg:grid-rows-1"
                : "",
            ])}>
            <div className="relative h-full min-h-0">
              <CameraView
                sessionLabel
                streamingEnabled={isLiveSession && streamingEnabled}
                elapsed
                stream
                // The live controls below float over the view's bottom edge.
                showSessionInfo={!isLiveSession}
                showBadges={!(isLiveSession && calibOpen)}
              />
              {isLiveSession && calibOpen
                ? <KioskCourtCalib
                    stream toolbarHost=calibToolbarHost onDone={() => onCalibDone()}
                  />
                : React.null}
              // The live controls FLOAT over the bottom of the video instead
              // of stacking below it: on short screens the stacked layout
              // squeezed the feed into a strip. The scrim keeps the white
              // cards readable over any footage; pointer-events split so the
              // transparent upper region still lets the video be tapped.
              // Hidden while the court-setup overlay is up: the controls would
              // sit on top of it (z-10) and cover the landmarks being placed.
              {isLiveSession && !calibOpen
                ? <div
                    className="pointer-events-none absolute inset-x-0 bottom-0 z-10 bg-gradient-to-t from-black/90 via-black/60 to-transparent p-3 pt-16 sm:p-4 sm:pt-20">
                    <div className="pointer-events-auto">
                      <LiveActionControls
                        onAction=onLiveAction
                        bufferStatus
                        clipEnabled
                        clipping
                        testMode
                        clips
                        onReview=onReviewClip
                      />
                      <div className="mt-3 flex items-center justify-between gap-3">
                        <div className="flex items-center gap-3">
                          <span
                            className="flex h-9 w-9 items-center justify-center border-2 border-red-400/40 bg-red-500/15">
                            <span className="h-2.5 w-2.5 bg-red-500" />
                          </span>
                          <p className="text-sm font-extrabold text-white">
                            {t`Rolling buffer active`}
                          </p>
                        </div>
                        <button
                          type_="button"
                          onClick={_ => onCalibOpen()}
                          className="mr-2 flex min-h-12 shrink-0 items-center justify-center gap-2 border-2 border-white/30 bg-black/40 px-4 text-sm font-extrabold text-white active:bg-white/10">
                          {t`Court setup`}
                        </button>
                        <button
                          type_="button"
                          onClick={_ => onEndLive()}
                          className="flex min-h-12 shrink-0 items-center justify-center gap-2 border-2 border-red-400/50 bg-red-500/20 px-5 text-sm font-extrabold text-red-200 transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-red-500/30">
                          <Lucide.Square \"aria-hidden"="true" className="fill-current" size=16 />
                          {t`End session`}
                        </button>
                      </div>
                    </div>
                  </div>
                : React.null}
            </div>
            {isLiveSession && streamingEnabled ? <LiveStreamShare /> : React.null}
          </div>
          {isLiveSession
            ? React.null // live controls are overlaid on the video above
            : <div
                className="mt-4 flex shrink-0 flex-col gap-4 border-2 border-kiosk-border bg-kiosk-surface p-4 sm:flex-row sm:items-stretch sm:justify-between sm:p-5">
                <div className="flex min-h-20 items-center gap-4">
                  <span
                    className="flex h-14 w-14 items-center justify-center border-2 border-red-400/40 bg-red-500/15">
                    <span className="h-3 w-3 bg-red-500" />
                  </span>
                  <div>
                    <p className="text-lg font-extrabold text-white"> {t`Analysis capture active`} </p>
                    <p className="text-sm text-kiosk-muted"> {analysisModeHelper(analysisMode)} </p>
                  </div>
                </div>
                <button
                  type_="button"
                  onClick={_ => onFinishAnalysis()}
                  className="flex min-h-20 shrink-0 items-center justify-center gap-3 border-2 border-kiosk-accent bg-kiosk-accent px-7 text-lg font-extrabold text-kiosk-bg transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-accentDark">
                  <Lucide.CheckCircle2 \"aria-hidden"="true" size=23 />
                  {t`End & analyze`}
                </button>
              </div>}
        </section>
      }
    }
  }
}

@react.component
let make = () => {
  let (category, setCategory) = React.useState(() => Live)
  let (selectedAnalysisMode, setSelectedAnalysisMode) = React.useState(() => DropShot)
  let (streamingEnabled, setStreamingEnabled) = React.useState(() => false)
  let (stage, setStage) = React.useState(() => Ready)
  let (resultMode, setResultMode) = React.useState(() => LiveResult(RallyClip))
  let (elapsed, setElapsed) = React.useState(() => 0)
  let (notice, setNotice) = React.useState(() => None)
  let (stream, setStream) = React.useState(() => None)
  let (settingsOpen, setSettingsOpen) = React.useState(() => false)
  let (cameras, setCameras) = React.useState(() => [])
  let (selectedCameraId, setSelectedCameraId) = React.useState(() => None)
  let (captureMode, setCaptureMode) = React.useState(() => CaptureSession.LocalRing)
  let (testMode, setTestMode) = React.useState(() => false)
  // The live capture session (rolling buffer). A ref, not state: handlers
  // need the current session without re-rendering on session identity.
  let sessionRef: React.ref<option<CaptureSession.t>> = React.useRef(None)
  let (captureStatus, setCaptureStatus) = React.useState(() => (None: option<CaptureSession.status>))
  let (clippingReady, setClippingReady) = React.useState(() => false)
  // Auto-saved clip history (newest first), the clip open in review, and
  // whether a takeClip is currently in flight.
  let (clips, setClips) = React.useState(() => ([]: array<clipState>))
  let (reviewClip, setReviewClip) = React.useState(() => (None: option<clipState>))
  let (challenge, setChallenge) = React.useState(() => (None: option<challengeState>))
  // Court calibration overlay: opens when a live session starts (prefilled
  // from the last confirmed corners), reopenable from the session controls.
  let (calibOpen, setCalibOpen) = React.useState(() => false)
  // The DOM node the calibration toolbar portals into. A STABLE callback ref
  // (useCallback0) so React only calls it on mount/unmount — a fresh closure
  // each render would detach/attach, set state, and re-render in a loop.
  let (calibToolbarHost, setCalibToolbarHost) = React.useState(() => (None: option<Dom.element>))
  let calibToolbarRef = React.useCallback0(el => setCalibToolbarHost(_ => el->Nullable.toOption))
  let (clipping, setClipping) = React.useState(() => false)
  let clipsRef: React.ref<array<clipState>> = React.useRef([])

  // Restore the persisted camera and capture-mode choices. Runs in an effect
  // because the page is SSR'd and localStorage only exists in the browser.
  React.useEffect0(() => {
    switch getStoredItem(cameraStorageKey)->Nullable.toOption {
    | Some(id) if id != "" => setSelectedCameraId(_ => Some(id))
    | _ => ()
    }
    switch getStoredItem(testModeStorageKey)->Nullable.toOption {
    | Some("1") => setTestMode(_ => true)
    | _ => ()
    }
    switch getStoredItem(CaptureSession.modeStorageKey)
    ->Nullable.toOption
    ->Option.flatMap(CaptureSession.modeFromString) {
    | Some(mode) => setCaptureMode(_ => mode)
    | None => ()
    }
    None
  })

  // Session timer shown in the camera overlay.
  React.useEffect2(() => {
    let liveSessionRunning = category == Live && stage != Ready
    if !liveSessionRunning && stage != Active {
      None
    } else {
      let timer = setInterval(() => setElapsed(value => value + 1), 1000)
      Some(() => clearInterval(timer))
    }
  }, (category, stage))

  // TODO(kiosk): replace this fake delay with the real pipelines for line
  // check and the analysis modes. The rally-clip path is real now — it
  // resolves itself via takeClip — so it is excluded here.
  React.useEffect2(() => {
    if (
      stage == Processing &&
      resultMode != LiveResult(RallyClip) &&
      resultMode != LiveResult(Challenge)
    ) {
      let timer = setTimeout(() => setStage(_ => Result), 1400)
      Some(() => clearTimeout(timer))
    } else {
      None
    }
  }, (stage, resultMode))

  React.useEffect1(() => {
    switch notice {
    | Some(_) =>
      let timer = setTimeout(() => setNotice(_ => None), 2800)
      Some(() => clearTimeout(timer))
    | None => None
    }
  }, [notice])

  // Stop the camera tracks whenever the stream is replaced, cleared, or the
  // page unmounts.
  React.useEffect1(() => {
    switch stream {
    | Some(stream) => Some(() => stream->UserMedia.stopAll)
    | None => None
    }
  }, [stream])

  // The capture session follows the camera stream, not the UI stage: it
  // starts when a live-session stream appears, survives Processing/Result
  // (its own hidden <video> keeps encoding while CameraView unmounts),
  // restarts when the camera switches (stream identity changes), and tears
  // down when the stream clears or the page unmounts. `category` is safe to
  // read from the closure: it only changes in Ready, where stream is None.
  React.useEffect1(() => {
    switch stream {
    | Some(currentStream) if category == Live => {
        let cancelled = ref(false)
        let session = Capture.makeSession(
          ~mode=captureMode,
          ~onStatus=status => setCaptureStatus(_ => Some(status)),
        )
        sessionRef.current = Some(session)
        setClippingReady(_ => false)
        let run = async () =>
          switch await session.start(currentStream) {
          | Ok() =>
            if cancelled.contents {
              session.stop()
            } else {
              setClippingReady(_ => true)
            }
          // The kiosk still works without clipping, but say why it is off:
          // log the reason and drop the status so the UI reads
          // "CLIPPING UNAVAILABLE" instead of a buffer stuck at 0s.
          | Error(error) => {
              Js.Console.error2("[kiosk] capture session failed to start:", error)
              session.stop()
              setCaptureStatus(_ => None)
            }
          }
        run()->ignore
        Some(
          () => {
            cancelled := true
            session.stop()
            sessionRef.current = None
            setClippingReady(_ => false)
            setCaptureStatus(_ => None)
          },
        )
      }
    | _ => None
    }
  }, [stream])

  // Deletion/eviction/session-end release URLs explicitly; this pair covers
  // the page unmounting with clips still in the history.
  React.useEffect1(() => {
    clipsRef.current = clips
    None
  }, [clips])
  React.useEffect0(() => Some(() => clipsRef.current->Array.forEach(releaseClip)))

  let stopCamera = () => setStream(_ => None)

  let resetSession = () => {
    setStage(_ => Ready)
    setElapsed(_ => 0)
    setReviewClip(_ => None)
    // Clip history is per-session; release the blobs when it ends. (Releasing
    // twice under StrictMode double-invoke is harmless.)
    setClips(previous => {
      previous->Array.forEach(releaseClip)
      []
    })
    stopCamera()
  }

  // Acquire a stream, degrading gracefully: exact camera with mic → exact
  // camera silent → any camera with mic → any camera silent. A denied mic
  // must never cost us the video feed, and a vanished camera falls back to
  // the system default.
  let acquireStream = async (devices, ~deviceId: option<string>, ~wantAudio: bool) => {
    let attempts = {
      let forDevice = wantAudio ? [(deviceId, true), (deviceId, false)] : [(deviceId, false)]
      switch deviceId {
      | Some(_) =>
        forDevice->Array.concat(wantAudio ? [(None, true), (None, false)] : [(None, false)])
      | None => forDevice
      }
    }
    let rec attempt = async index =>
      switch attempts->Array.get(index) {
      | None => None
      | Some((deviceId, audio)) => {
          let acquired = try {
            Some(await devices->UserMedia.getUserMedia(UserMedia.constraintsFor(~deviceId, ~audio)))
          } catch {
          | _ => None
          }
          switch acquired {
          | Some(stream) => Some(stream)
          | None => await attempt(index + 1)
          }
        }
      }
    await attempt(0)
  }

  let refreshCameras = async () => {
    switch UserMedia.mediaDevices->Nullable.toOption {
    | None => setCameras(_ => [])
    | Some(devices) =>
      try {
        let all = await devices->UserMedia.enumerateDevices
        let videoInputs = all->Array.filter(d => d.kind == "videoinput")
        // Device labels stay blank until camera permission has been granted
        // once; grab and immediately release a throwaway stream so the picker
        // can show real names.
        let needsPriming =
          videoInputs->Array.length > 0 && videoInputs->Array.every(d => d.label == "")
        let videoInputs = if needsPriming {
          try {
            let primed = await devices->UserMedia.getUserMedia(
              UserMedia.constraintsFor(~deviceId=None, ~mode=BrowserDefault),
            )
            primed->UserMedia.stopAll
            let all = await devices->UserMedia.enumerateDevices
            all->Array.filter(d => d.kind == "videoinput")
          } catch {
          // Permission denied: fall back to the unlabeled list.
          | _ => videoInputs
          }
        } else {
          videoInputs
        }
        setCameras(_ => videoInputs)
      } catch {
      | _ => setCameras(_ => [])
      }
    }
  }

  let openSettings = () => {
    setSettingsOpen(_ => true)
    refreshCameras()->ignore
  }

  // Keep the picker current while it's open if a camera is (un)plugged.
  React.useEffect1(() => {
    if settingsOpen {
      switch UserMedia.mediaDevices->Nullable.toOption {
      | Some(devices) =>
        let handler = () => refreshCameras()->ignore
        devices->UserMedia.addDeviceChangeListener(handler)
        Some(() => devices->UserMedia.removeDeviceChangeListener(handler))
      | None => None
      }
    } else {
      None
    }
  }, [settingsOpen])

  let selectCamera = async (deviceId: option<string>) => {
    setSelectedCameraId(_ => deviceId)
    switch deviceId {
    | Some(id) => setStoredItem(cameraStorageKey, id)
    | None => removeStoredItem(cameraStorageKey)
    }
    // If a session is running, switch the live feed over immediately. The
    // stream effects stop the old camera and restart the capture session once
    // the new stream replaces it.
    switch (stream, UserMedia.mediaDevices->Nullable.toOption) {
    | (Some(_), Some(devices)) =>
      switch await acquireStream(devices, ~deviceId, ~wantAudio=category == Live) {
      | Some(next) => setStream(_ => Some(next))
      | None => setNotice(_ => Some(CameraError))
      }
    | _ => ()
    }
  }

  let selectCaptureMode = (mode: CaptureSession.mode) => {
    setCaptureMode(_ => mode)
    setStoredItem(CaptureSession.modeStorageKey, CaptureSession.modeToString(mode))
  }

  // Ask for the device camera (with mic in live sessions, for clip audio) and
  // show the live feed in the session workspace.
  let startSession = async () => {
    if testMode && category == Live {
      // No camera required: the placeholder court renders, the buffer stays
      // empty, and Challenge uses the server's fixed test clip. Calibration
      // is skipped — the test clip carries its own court pkl server-side.
      setStream(_ => None)
      setElapsed(_ => 0)
      setStage(_ => Active)
    } else {
      switch UserMedia.mediaDevices->Nullable.toOption {
    | None => setNotice(_ => Some(CameraError))
    | Some(devices) =>
      switch await acquireStream(devices, ~deviceId=selectedCameraId, ~wantAudio=category == Live) {
      | Some(cameraStream) => {
          setStream(_ => Some(cameraStream))
          setElapsed(_ => 0)
          setStage(_ => Active)
          if category == Live {
            setCalibOpen(_ => true)
          }
        }
      | None => setNotice(_ => Some(CameraError))
      }
      }
    }
  }

  let handleLiveAction = (action: liveAction) =>
    switch action {
    // Auto-save: the clip muxes in the background and drops into the history
    // strip; the UI stays live and can clip again as soon as it finishes.
    | RallyClip =>
      if !clipping {
        setClipping(_ => true)
        let run = async () => {
          switch sessionRef.current {
          | Some(session) =>
            switch await session.takeClip() {
            | Ok(result) => {
                let clip = {
                  url: CaptureSession.createObjectURL(result.blob),
                  durationSeconds: result.durationSeconds,
                  hasAudio: result.hasAudio,
                  capturedAt: timeLabel(),
                  frameTimes: result.frameTimes,
                }
                setClips(previous => {
                  let next = [clip]->Array.concat(previous)
                  if next->Array.length > maxClipHistory {
                    next->Array.sliceToEnd(~start=maxClipHistory)->Array.forEach(releaseClip)
                    next->Array.slice(~start=0, ~end=maxClipHistory)
                  } else {
                    next
                  }
                })
                setNotice(_ => Some(ClipSaved))
              }
            | Error(error) => {
                Js.Console.error2("[kiosk] takeClip failed:", error)
                setNotice(_ => Some(ClipFailed))
              }
            }
          | None => setNotice(_ => Some(ClipFailed))
          }
          setClipping(_ => false)
        }
        run()->ignore
      }
    // Challenge: freeze the buffer into a clip, ship it to the dinkhunt
    // analysis server, and review its ground bounces. The clip is reviewable
    // even when analysis fails (the error shows in the panel).
    | Challenge =>
      if !clipping {
        setClipping(_ => true)
        setResultMode(_ => LiveResult(Challenge))
        setStage(_ => Processing)
        let run = async () => {
          if testMode {
            // Fixed test clip: fetch it for playback, analyze it BY NAME on
            // the server (it already holds the file — nothing to upload).
            switch await DinkHunt.fetchTestClip() {
            | Ok(blobData) => {
                let url = CaptureSession.createObjectURL(blobData)
                let duration = await DinkHunt.urlDuration(url)
                let analysis = await DinkHunt.testChallengeAnalysis()
                let clip = {
                  url,
                  durationSeconds: duration,
                  hasAudio: false,
                  capturedAt: timeLabel(),
                  // A test clip has no capture timeline of its own: the server's
                  // per-frame timestamps of the same file map analysis time onto
                  // the video. Without them the overlay assumed analysis time IS
                  // video time and trailed the ball (measured: 0.30 s by 15 s on a
                  // 14-18 ms variable-rate export analysed at 58.84 fps).
                  frameTimes: switch analysis {
                  | Ok(a) => a.frameTimes
                  | Error(_) => []
                  },
                }
                let (bounces, paths, frameW, frameH, fps, error) = switch analysis {
                | Ok(a) => (a.bounces, a.paths, a.width, a.height, a.fps, None)
                | Error(message) => ([], [], 1920, 1080, 30., Some(message))
                }
                setChallenge(_ => Some({clip, bounces, paths, frameW, frameH, fps, error}))
                setStage(_ => Result)
              }
            | Error(message) => {
                Js.Console.error2("[kiosk] test clip fetch failed:", message)
                setNotice(_ => Some(TestClipMissing))
                setStage(_ => Active)
              }
            }
            setClipping(_ => false)
          } else {
          switch sessionRef.current {
          | Some(session) =>
            switch await session.takeClip(~seconds=challengeSeconds) {
            | Ok(result) => {
                let clip = {
                  url: CaptureSession.createObjectURL(result.blob),
                  durationSeconds: result.durationSeconds,
                  hasAudio: result.hasAudio,
                  capturedAt: timeLabel(),
                  frameTimes: result.frameTimes,
                }
                // Crop to the court's analysis region (the same rectangle the
                // calibration was sent in) before upload; the full clip stays
                // for playback and the results are shifted back afterwards.
                let (nativeW, nativeH) = switch result.encoded {
                | Some(enc) => (enc.width, enc.height)
                | None => (1920, 1080)
                }
                let crop = result.encoded->Option.flatMap(enc =>
                  KioskCourtCalib.loadStoredPlaced(~width=enc.width, ~height=enc.height)->Option.flatMap(
                    placed => KioskCourtCalib.cropRegion(placed, enc.width, enc.height),
                  )
                )
                let analysisBlob = switch (crop, result.encoded) {
                | (Some(rect), Some(enc)) => await ClipCrop.crop(enc, rect)
                | _ => Ok(result.blob)
                }
                let (bounces, paths, frameW, frameH, fps, error) = switch analysisBlob {
                | Error(message) => ([], [], nativeW, nativeH, 30., Some("crop failed: " ++ message))
                | Ok(blob) =>
                  switch await DinkHunt.challengeBounces(blob) {
                  | Ok((_upload, a)) => {
                      let a = reprojectAnalysis(a, crop)
                      (a.bounces, a.paths, nativeW, nativeH, a.fps, None)
                    }
                  | Error(message) => ([], [], nativeW, nativeH, 30., Some(message))
                  }
                }
                setChallenge(_ => Some({clip, bounces, paths, frameW, frameH, fps, error}))
                setStage(_ => Result)
              }
            | Error(error) => {
                Js.Console.error2("[kiosk] challenge takeClip failed:", error)
                setNotice(_ => Some(ClipFailed))
                setStage(_ => Active)
              }
            }
          | None => {
              setNotice(_ => Some(ClipFailed))
              setStage(_ => Active)
            }
          }
          setClipping(_ => false)
          }
        }
        run()->ignore
      }
    }

  // Open an auto-saved clip from the history strip in the review panel.
  let handleReviewClip = (clip: clipState) => {
    setReviewClip(_ => Some(clip))
    setResultMode(_ => LiveResult(RallyClip))
    setStage(_ => Result)
  }

  let handleDeleteClip = () => {
    switch reviewClip {
    | Some(clip) => {
        releaseClip(clip)
        setClips(previous => previous->Array.filter(existing => existing.url != clip.url))
      }
    | None => ()
    }
    setReviewClip(_ => None)
    setStage(_ => Active)
  }

  // TODO(kiosk): run the selected analysis over the captured session.
  let handleFinishAnalysis = () => {
    setResultMode(_ => AnalysisResult(selectedAnalysisMode))
    setStage(_ => Processing)
  }

  let handleResultDone = () => {
    setReviewClip(_ => None)
    switch challenge {
    | Some(existing) => releaseClip(existing.clip)
    | None => ()
    }
    setChallenge(_ => None)
    switch category {
    | Live => setStage(_ => Active)
    | Analysis => resetSession()
    }
  }

  // "Save clip" in review = optional local download; stay on the review
  // screen. TODO(kiosk): upload to the server once an endpoint exists.
  let handleSaved = () => setNotice(_ => Some(ClipDownloaded))

  let handleEndLive = () => {
    resetSession()
    setNotice(_ => Some(LiveEnded))
  }

  let inSession = stage != Ready
  let activeTitle = category == Live ? t`Live rolling session` : analysisModeName(selectedAnalysisMode)
  // Clip needs a started session plus at least one closed GOP (~2s) to work.
  let clipEnabled =
    clippingReady && captureStatus->Option.mapOr(false, status => status.bufferedSeconds >= 2.)
  // The active capture screen locks to the viewport (video flexes to fill,
  // controls hug the bottom); every other screen scrolls normally.
  let fullScreenSession = stage == Active
  // Court setup is showing (it only renders over a live session's feed).
  let calibrating = calibOpen && category == Live && stage == Active

  <div
    className={cx([
      "w-full bg-kiosk-bg text-white",
      fullScreenSession ? "flex h-dvh flex-col overflow-hidden" : "min-h-screen",
    ])}>
    <header className="shrink-0 border-b border-kiosk-border bg-kiosk-surface">
      <div className="mx-auto flex min-h-20 max-w-[1500px] items-center justify-between px-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-3">
          <span className="flex h-14 w-14 items-center justify-center bg-kiosk-accent text-kiosk-bg">
            <Lucide.Camera \"aria-hidden"="true" size=28 strokeWidth=2.4 />
          </span>
          <div>
            <p className="text-lg font-extrabold tracking-tight">
              {React.string("COURTSIDE")}
              <span className="text-kiosk-accent"> {React.string(".AI")} </span>
            </p>
            <p className="text-xs text-kiosk-muted"> {t`Pickleball camera kiosk`} </p>
          </div>
        </div>
        <div className="flex items-center gap-2 sm:gap-3">
          <span
            className="hidden min-h-14 items-center gap-2 border border-kiosk-border px-4 text-xs font-medium text-kiosk-muted sm:flex">
            <Lucide.Wifi \"aria-hidden"="true" className="text-kiosk-accent" size=17 />
            {t`Camera connected`}
          </span>
          <button
            type_="button"
            ariaLabel={Lingui.UtilString.t`Open kiosk settings`}
            onClick={_ => openSettings()}
            className="flex h-14 w-14 items-center justify-center border-2 border-kiosk-border bg-kiosk-raised text-kiosk-muted transition-[background-color,color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-border active:text-white">
            <Lucide.Settings \"aria-hidden"="true" size=24 />
          </button>
        </div>
      </div>
    </header>
    <main
      className={cx([
        "mx-auto w-full max-w-[1500px] px-4 sm:px-6 lg:px-8",
        fullScreenSession ? "flex min-h-0 flex-1 flex-col py-4" : "py-6 lg:py-8",
      ])}>
      {inSession
        ? <>
            {calibrating
              ? // Court setup's toolbar portals in here, so nothing covers
                // the frame being calibrated (the back button returns after).
                <div
                  ref={ReactDOM.Ref.callbackDomRef(calibToolbarRef)} className="mb-3 shrink-0"
                />
              : <button
              type_="button"
              onClick={_ => category == Live ? handleEndLive() : resetSession()}
              className={cx([
                "flex min-h-16 shrink-0 items-center gap-3 border-2 border-kiosk-border bg-kiosk-surface px-5 font-bold text-kiosk-muted transition-[background-color,color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-raised active:text-white",
                fullScreenSession ? "mb-4 self-start" : "mb-5",
              ])}>
              <Lucide.ArrowLeft \"aria-hidden"="true" size=23 />
              {category == Live ? t`End session and exit` : t`Back to modes`}
            </button>}
            <SessionWorkspace
              category
              analysisMode=selectedAnalysisMode
              resultMode
              stage
              elapsed
              streamingEnabled
              stream
              reviewClip
              challenge
              calibOpen
              calibToolbarHost
              onCalibDone={() => setCalibOpen(_ => false)}
              onCalibOpen={() => setCalibOpen(_ => true)}
              testMode
              clips
              clipping
              bufferStatus=captureStatus
              clipEnabled
              onLiveAction=handleLiveAction
              onReviewClip=handleReviewClip
              onDeleteClip=handleDeleteClip
              onFinishAnalysis=handleFinishAnalysis
              onEndLive=handleEndLive
              onResultDone=handleResultDone
              onSaved=handleSaved
            />
          </>
        : <div className="grid gap-8 lg:grid-cols-[minmax(0,0.9fr)_minmax(520px,1.1fr)] lg:gap-12">
            <section className="flex flex-col justify-center lg:pr-4">
              <div className="flex items-baseline justify-between gap-4">
                <h1 className="text-2xl font-extrabold tracking-tight sm:text-3xl">
                  {category == Live ? t`Live session` : t`Analysis setup`}
                </h1>
                <p className="shrink-0 font-mono text-xs font-semibold text-kiosk-accent">
                  {React.string("COURT 04 · READY")}
                </p>
              </div>
              <p className="mt-2 text-sm text-kiosk-muted">
                {category == Live
                  ? t`Rolling capture with optional YouTube streaming.`
                  : t`Select a mode, then start capture.`}
              </p>
              <div className="mt-5 border-2 border-kiosk-border bg-kiosk-surface p-4 sm:p-6">
                <p className="font-mono text-sm font-semibold text-kiosk-muted">
                  {category == Live ? t`SESSION SETUP` : t`SELECTED ANALYSIS`}
                </p>
                <h2 className="mt-2 text-2xl font-extrabold"> activeTitle </h2>
                {category == Live
                  ? // TODO(kiosk): actually start a YouTube stream when enabled.
                    <button
                      type_="button"
                      role="switch"
                      ariaChecked={streamingEnabled ? #"true" : #"false"}
                      onClick={_ => setStreamingEnabled(enabled => !enabled)}
                      className={cx([
                        "mt-6 flex min-h-24 w-full items-center justify-between gap-4 border-2 p-4 text-left transition-[background-color,border-color,transform] duration-150 ease-out active:translate-y-1",
                        streamingEnabled
                          ? "border-red-400 bg-red-500 text-white"
                          : "border-kiosk-border bg-kiosk-raised text-white",
                      ])}>
                      <span className="flex min-w-0 items-center gap-4">
                        <span
                          className={cx([
                            "flex h-14 w-14 shrink-0 items-center justify-center border-2",
                            streamingEnabled ? "border-white/50" : "border-kiosk-border text-kiosk-muted",
                          ])}>
                          <Lucide.Radio \"aria-hidden"="true" size=25 />
                        </span>
                        <span>
                          <span className="block text-lg font-extrabold"> {t`Stream on YouTube`} </span>
                          <span
                            className={cx([
                              "mt-1 block text-sm",
                              streamingEnabled ? "text-white/75" : "text-kiosk-muted",
                            ])}>
                            {t`Show a viewer QR code during the session`}
                          </span>
                        </span>
                      </span>
                      <span
                        className={cx([
                          "shrink-0 border-2 px-4 py-2 font-mono text-sm font-bold",
                          streamingEnabled
                            ? "border-white bg-white text-red-600"
                            : "border-kiosk-muted text-kiosk-muted",
                        ])}>
                        {streamingEnabled ? t`ON` : t`OFF`}
                      </span>
                    </button>
                  : React.null}
                <button
                  type_="button"
                  onClick={_ => startSession()->ignore}
                  className="mt-4 flex min-h-24 w-full items-center justify-center gap-4 border-2 border-kiosk-accent bg-kiosk-accent px-6 text-xl font-extrabold text-kiosk-bg transition-[background-color,transform] duration-150 ease-out active:translate-y-1 active:bg-kiosk-accentDark">
                  <Lucide.Play \"aria-hidden"="true" className="fill-current" size=27 />
                  {category == Live ? t`Start live session` : t`Start analysis`}
                </button>
                <div className="mt-4 flex items-center gap-2 text-sm text-kiosk-muted">
                  <Lucide.CheckCircle2 \"aria-hidden"="true" className="text-kiosk-accent" size=17 />
                  {t`Camera framing and connection look good`}
                </div>
              </div>
            </section>
            <section className="border-2 border-kiosk-border bg-kiosk-surface/50 p-4 sm:p-6">
              <div className="grid grid-cols-2 border-2 border-kiosk-border bg-kiosk-raised" role="tablist">
                <button
                  type_="button"
                  role="tab"
                  ariaSelected={category == Live}
                  onClick={_ => setCategory(_ => Live)}
                  className={cx([
                    "min-h-20 whitespace-nowrap border-r-2 border-kiosk-border px-4 text-lg font-extrabold transition-[background-color,color,transform] duration-150 ease-out active:translate-y-1",
                    category == Live
                      ? "bg-white text-kiosk-bg"
                      : "text-kiosk-muted active:bg-kiosk-border active:text-white",
                  ])}>
                  {t`Live game`}
                </button>
                <button
                  type_="button"
                  role="tab"
                  ariaSelected={category == Analysis}
                  onClick={_ => setCategory(_ => Analysis)}
                  className={cx([
                    "min-h-20 whitespace-nowrap px-4 text-lg font-extrabold transition-[background-color,color,transform] duration-150 ease-out active:translate-y-1",
                    category == Analysis
                      ? "bg-white text-kiosk-bg"
                      : "text-kiosk-muted active:bg-kiosk-border active:text-white",
                  ])}>
                  {t`Analysis`}
                </button>
              </div>
              {category == Live
                ? <div className="mt-6">
                    <h2 className="text-xl font-bold"> {t`Available while playing`} </h2>
                    <p className="mt-1 text-sm text-kiosk-muted">
                      {t`No action selection is needed before starting.`}
                    </p>
                    <div className="mt-5 overflow-hidden border-2 border-kiosk-border bg-kiosk-surface">
                      {[RallyClip, Challenge]
                      ->Array.mapWithIndex((action, index) => {
                        let icon = switch action {
                        | RallyClip => <Lucide.Scissors \"aria-hidden"="true" size=28 />
                        | Challenge => <Lucide.Target \"aria-hidden"="true" size=28 />
                        }
                        <div
                          key={liveActionKey(action)}
                          className={cx([
                            "flex min-h-28 items-center gap-5 p-5",
                            index > 0 ? "border-t-2 border-kiosk-border" : "",
                          ])}>
                          <span
                            className="flex h-16 w-16 shrink-0 items-center justify-center border-2 border-kiosk-border bg-kiosk-raised text-kiosk-accent">
                            icon
                          </span>
                          <div>
                            <h3 className="text-lg font-extrabold text-white"> {liveActionName(action)} </h3>
                            <p className="mt-1 text-sm leading-5 text-kiosk-muted">
                              {liveActionDescription(action)}
                            </p>
                          </div>
                        </div>
                      })
                      ->React.array}
                    </div>
                    <div
                      className="mt-4 flex min-h-20 items-center gap-4 border-l-4 border-kiosk-accent bg-kiosk-accent/10 p-4 text-sm text-kiosk-muted">
                      <Lucide.History \"aria-hidden"="true" className="shrink-0 text-kiosk-accent" size=24 />
                      <p> {t`The camera continuously keeps recent play ready for either action.`} </p>
                    </div>
                  </div>
                : <div className="mt-6">
                    <h2 className="text-xl font-bold"> {t`Analysis modes`} </h2>
                    <p className="mt-1 text-sm text-kiosk-muted"> {t`Select one before starting the camera.`} </p>
                    <div className="mt-4 grid gap-3">
                      {[DropShot, ServeSpeed]
                      ->Array.map(mode =>
                        <ModeCard
                          key={analysisModeKey(mode)}
                          mode
                          selected={selectedAnalysisMode == mode}
                          onSelect={mode => setSelectedAnalysisMode(_ => mode)}
                        />
                      )
                      ->React.array}
                    </div>
                  </div>}
            </section>
          </div>}
    </main>
    {settingsOpen
      ? <SettingsPanel
          testMode
          onToggleTestMode={() => {
            let next = !testMode
            setTestMode(_ => next)
            setStoredItem(testModeStorageKey, next ? "1" : "0")
          }}
          cameras
          selectedCameraId
          onSelect={deviceId => selectCamera(deviceId)->ignore}
          captureMode
          onSelectMode=selectCaptureMode
          onClose={() => setSettingsOpen(_ => false)}
        />
      : React.null}
    {switch notice {
    | Some(notice) =>
      <div
        role="status"
        className="fixed bottom-5 left-1/2 z-50 flex min-h-16 -translate-x-1/2 items-center gap-3 whitespace-nowrap border-2 border-kiosk-accent bg-kiosk-raised px-6 font-bold text-white">
        <Lucide.CheckCircle2 \"aria-hidden"="true" className="text-kiosk-accent" size=22 />
        {switch notice {
        | ClipSaved => t`Clip saved · live capture continues`
        | LiveEnded => t`Live session ended`
        | CameraError => t`Camera unavailable — check permissions and try again`
        | ClipFailed => t`Could not create the clip — the buffer keeps recording`
        | TestClipMissing =>
          t`Test clip not found — put test_challenge.mov in the dinkhunt folder (and restart nothing; it is picked up live)`
        | ClipDownloaded => t`Clip downloaded`
        }}
      </div>
    | None => React.null
    }}
  </div>
}
