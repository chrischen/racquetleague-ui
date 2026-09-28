// Maps between a clip's REAL playback timeline (the muxed frames' capture
// timestamps: seconds, frame 0 = 0) and the analysis server's UNIFORM time
// (t = frameIndex / fps, with fps the median frame spacing). Cameras change
// frame rate under auto-exposure and the encoder drops frames under load, so
// the two agree only on a perfect grid — an overlay drawn at "analysis t =
// video now" drifts ahead of the real ball where frames came slower than the
// median and behind where they came faster. Everything here is pure; an empty
// frame table degrades to the identity mapping. Recorded clips use the capture
// timestamps; test clips use the server's per-frame timestamps of the file.

type t = {
  frameTimes: array<float>, // seconds, ascending, frameTimes[0] == 0.
  fps: float, // the analysis fps: analysis t = frameIndex / fps
}

let make = (~frameTimes: array<float>, ~fps: float): t => {frameTimes, fps}

let isIdentity = (timeline: t) => timeline.frameTimes->Array.length < 2 || timeline.fps <= 0.

let frameCount = (timeline: t) => timeline.frameTimes->Array.length

let timeAt = (timeline: t, index: int) => {
  let n = frameCount(timeline)
  let clamped = index < 0 ? 0 : index >= n ? n - 1 : index
  timeline.frameTimes->Array.getUnsafe(clamped)
}

// Largest k with frameTimes[k] <= videoTime (0 before the first frame).
let frameIndexAt = (timeline: t, videoTime: float): int =>
  if isIdentity(timeline) {
    Math.Int.max(0, Math.floor(videoTime *. timeline.fps)->Float.toInt)
  } else {
    let lo = ref(0)
    let hi = ref(frameCount(timeline) - 1)
    while lo.contents < hi.contents {
      let mid = (lo.contents + hi.contents + 1) / 2
      if timeline.frameTimes->Array.getUnsafe(mid) <= videoTime {
        lo := mid
      } else {
        hi := mid - 1
      }
    }
    lo.contents
  }

// Fractional frame position at a video time: k + progress through [k, k+1].
// Beyond the last frame it keeps extrapolating with the last interval so a
// marker near the clip's end still moves.
let framePositionAt = (timeline: t, videoTime: float): float =>
  if isIdentity(timeline) {
    Math.max(0., videoTime *. timeline.fps)
  } else {
    let n = frameCount(timeline)
    let k = frameIndexAt(timeline, videoTime)
    let tk = timeAt(timeline, k)
    let span = if k + 1 < n {
      timeAt(timeline, k + 1) -. tk
    } else {
      tk -. timeAt(timeline, k - 1)
    }
    let progress = span <= 0. ? 0. : (videoTime -. tk) /. span
    Math.max(0., Int.toFloat(k) +. progress)
  }

// Video time -> analysis time (what the paths/bounces are expressed in).
let toAnalysis = (timeline: t, videoTime: float): float =>
  isIdentity(timeline) ? videoTime : framePositionAt(timeline, videoTime) /. timeline.fps

// Analysis time -> video time (where to seek / when a marker appears).
let toVideo = (timeline: t, analysisTime: float): float =>
  if isIdentity(timeline) {
    analysisTime
  } else {
    let n = frameCount(timeline)
    let position = Math.max(0., analysisTime *. timeline.fps)
    let k = Math.Int.min(Math.floor(position)->Float.toInt, n - 1)
    let progress = position -. Int.toFloat(k)
    let tk = timeAt(timeline, k)
    let span = if k + 1 < n {
      timeAt(timeline, k + 1) -. tk
    } else {
      tk -. timeAt(timeline, k - 1)
    }
    tk +. progress *. span
  }

// Video time reached by stepping a whole number of frames from a video time,
// landing exactly on a frame's own timestamp.
let stepFrames = (timeline: t, videoTime: float, frames: int): float =>
  if isIdentity(timeline) {
    Math.max(0., videoTime +. Int.toFloat(frames) /. timeline.fps)
  } else {
    let current = Math.round(framePositionAt(timeline, videoTime))->Float.toInt
    timeAt(timeline, current + frames)
  }
