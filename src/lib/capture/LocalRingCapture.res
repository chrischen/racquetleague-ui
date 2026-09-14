// The on-device implementation of CaptureSession: a WebCodecs rolling buffer.
//
// Video: a session-owned hidden <video> (kept in the DOM — Safari's
// requestVideoFrameCallback is tied to the rendering pipeline and can go
// silent on detached or display:none elements) feeds VideoFrames into a
// hardware H.264 VideoEncoder; encoded chunks land in a keyframe-aligned
// ClipRing. Owning the element means capture survives the kiosk's visible
// camera view unmounting during clip review.
//
// Audio: MediaStreamTrackProcessor (Safari ships it for audio tracks) feeds
// AudioData into an AAC/Opus AudioEncoder and a time-window SampleRing.
// Anything missing on the audio side degrades to silent clips.
//
// takeClip muxes a snapshot of both rings into a fast-start MP4 without
// pausing capture.

type payload = Uint8Array.t

let targetSeconds = 20.
let targetDurationUs = 20_000_000.
let keepDurationUs = 24_000_000.
let maxRingBytes = 64 * 1024 * 1024
let keyframeIntervalUs = 2_000_000.
// Skip (and count) frames when the encoder queue backs up this far.
let maxVideoQueue = 2
let maxAudioQueue = 8
let firstFrameTimeoutMs = 5000
let flushTimeoutMs = 1500

// Private DOM externals for the hidden capture element.
@val @scope("document") external createElement: string => Dom.element = "createElement"
@val @scope("document") external documentBody: Dom.element = "body"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send external removeElement: Dom.element => unit = "remove"
@set external setMuted: (Dom.element, bool) => unit = "muted"
@set external setPlaysInline: (Dom.element, bool) => unit = "playsInline"
type elementStyle
@get external style: Dom.element => elementStyle = "style"
@set external setCssText: (elementStyle, string) => unit = "cssText"
@send external play: Dom.element => promise<unit> = "play"

type state = {
  mutable running: bool,
  mutable video: option<Dom.element>,
  mutable rvfc: option<WebCodecs.rvfcHandle>,
  mutable videoEncoder: option<WebCodecs.videoEncoder>,
  mutable videoCodec: option<string>,
  mutable videoDecoderConfig: option<WebCodecs.decoderConfig>,
  mutable videoConfiguring: bool,
  mutable width: int,
  mutable height: int,
  // The track's delivered frame rate (from getSettings at start); sizes the
  // encoder's bitrate and level.  30 when the track does not report one.
  mutable frameRate: float,
  mutable lastKeyUs: float,
  // Video and audio timestamps come from different clocks (video: media
  // timeline starting near 0; audio: often a machine-uptime clock). The
  // epoch, captured when the first AudioData arrives, maps audio timestamps
  // onto the video timeline so clip range selection can line them up.
  mutable lastVideoTsUs: float,
  mutable audioEpochUs: option<float>,
  mutable ring: ClipRing.t<payload>,
  mutable audioRing: SampleRing.t<payload>,
  mutable audioEncoder: option<WebCodecs.audioEncoder>,
  mutable audioContainerCodec: option<string>, // "aac" | "opus"
  mutable audioCodecString: option<string>, // e.g. "mp4a.40.2"
  mutable audioConfiguring: bool,
  mutable audioDecoderConfig: option<WebCodecs.audioDecoderConfig>,
  mutable audioSampleRate: float,
  mutable audioChannels: int,
  mutable audioReader: option<WebCodecs.reader>,
  mutable droppedFrames: int,
  // Feeding encoders during flush() makes Chromium emit out-of-order chunks
  // (a forced keyframe stamped before already-queued frames); pause both
  // pipelines while a takeClip flush is in flight.
  mutable flushing: bool,
  mutable statusTimer: option<intervalId>,
  // start()'s pending resolver; settled by the first encoded chunk, a codec
  // probe failure, the watchdog, or stop().
  mutable resolveStart: option<result<unit, CaptureSession.startError> => unit>,
}

let settleStart = (state, result: result<unit, CaptureSession.startError>) =>
  switch state.resolveStart {
  | Some(resolve) => {
      state.resolveStart = None
      resolve(result)
    }
  | None => ()
  }

let onVideoChunk = (
  state,
  chunk: WebCodecs.encodedVideoChunk,
  meta: Nullable.t<WebCodecs.chunkMetadata>,
) =>
  if state.running {
    switch meta->Nullable.toOption {
    | Some(meta) =>
      // The first chunk's metadata carries the avcC description the muxer needs.
      switch meta.decoderConfig {
      | Some(decoderConfig) =>
        if state.videoDecoderConfig->Option.isNone {
          state.videoDecoderConfig = Some(decoderConfig)
        }
      | None => ()
      }
    | None => ()
    }
    let byteLength = chunk->WebCodecs.chunkByteLength
    let bytes = Uint8Array.fromLength(byteLength)
    chunk->WebCodecs.copyTo(bytes)
    state.ring = ClipRing.push(
      state.ring,
      {
        timestampUs: chunk->WebCodecs.chunkTimestamp,
        durationUs: chunk->WebCodecs.chunkDuration->Nullable.toOption->Option.getOr(0.),
        isKey: chunk->WebCodecs.chunkType == "key",
        byteLength,
        payload: bytes,
      },
    )
    settleStart(state, Ok())
  }

// Lazy encoder init from the first frame's real dimensions (more trustworthy
// than track.getSettings() on Safari). Probes a codec ladder sequentially.
let configureVideo = async (state, metadata: WebCodecs.frameMetadata) => {
  let width = metadata.width
  let height = metadata.height
  let pixels = Int.toFloat(width * height)
  let fps = state.frameRate
  // ~6 Mb/s per 1080p30 of court motion, scaled by pixels and frame rate.
  // The ring is native resolution on purpose (clips and the Challenge
  // player show the camera's real frames; only the detector downscales), and
  // at 20 s it stays cheap: 1080p60 → 12 Mb/s → 30 MB.
  let bitrate = Math.min(
    24_000_000.,
    Math.max(1_500_000., 6_000_000. *. pixels /. (1920. *. 1080.) *. Math.max(1., fps /. 30.)),
  )
  // H.264 level ladders by picture size: 4.2 covers 1080p60 (4.0 stops at
  // 1080p30), 5.1/5.2 cover 4K.  A level too small for the picture is what
  // isConfigSupported rejects, so each ladder starts at the level its size
  // needs and falls back to the more widely supported ones.
  let candidates = if width * height > 1920 * 1088 {
    ["avc1.640033", "avc1.640034", "avc1.4d0033"]
  } else if width * height > 1280 * 720 {
    ["avc1.64002a", "avc1.640028", "avc1.4d002a", "avc1.4d0028", "avc1.42e028"]
  } else {
    ["avc1.4d001f", "avc1.42e01f", "avc1.640028"]
  }
  let rec probe = async index =>
    switch candidates->Array.get(index) {
    | None => None
    | Some(codec) => {
        let config: WebCodecs.encoderConfig = {
          codec,
          width,
          height,
          bitrate,
          framerate: fps,
          latencyMode: "realtime",
          avc: {format: "avc"}, // out-of-band avcC; Annex B would break the MP4
          hardwareAcceleration: "no-preference",
        }
        let supported = try {
          (await WebCodecs.isConfigSupported(config)).supported
        } catch {
        | _ => false
        }
        supported ? Some(config) : await probe(index + 1)
      }
    }
  switch await probe(0) {
  | None => settleStart(state, Error(CaptureSession.NoSupportedCodec))
  | Some(config) =>
    if state.running {
      try {
        let encoder = WebCodecs.makeEncoder({
          output: (chunk, meta) => onVideoChunk(state, chunk, meta),
          error: _ => (),
        })
        encoder->WebCodecs.configure(config)
        state.videoEncoder = Some(encoder)
        state.videoCodec = Some(config.codec)
        state.width = width
        state.height = height
      } catch {
      | _ => settleStart(state, Error(CaptureSession.NoSupportedCodec))
      }
    }
  }
}

let encodeFrame = (state, video, encoder, nowMs: float) =>
  // Check backpressure BEFORE constructing the frame — building and dropping
  // one still consumes a slot in the browser's frame pool.
  if state.flushing || encoder->WebCodecs.encodeQueueSize > maxVideoQueue {
    state.droppedFrames = state.droppedFrames + 1
  } else {
    // Timestamps come from rVFC's `now` (performance.now domain), NOT
    // metadata.mediaTime: WebKit reports mediaTime as a constant 0 for
    // getUserMedia-backed video elements, which froze the whole ring.
    // Everything downstream is relative, so any monotonic clock works.
    let timestampUs = nowMs *. 1_000.
    state.lastVideoTsUs = timestampUs
    switch try {
      Some(WebCodecs.videoFrameFromElement(video, {timestamp: timestampUs}))
    } catch {
    | _ => None
    } {
    | None => state.droppedFrames = state.droppedFrames + 1
    | Some(frame) => {
        let keyFrame = timestampUs -. state.lastKeyUs >= keyframeIntervalUs
        if keyFrame {
          state.lastKeyUs = timestampUs
        }
        // encode() clones; our reference must be closed on every path, even
        // when encode throws during a teardown race.
        try {
          encoder->WebCodecs.encode(frame, {keyFrame: keyFrame})
        } catch {
        | _ => ()
        }
        frame->WebCodecs.closeFrame
      }
    }
  }

let onAudioChunk = (
  state,
  chunk: WebCodecs.encodedAudioChunk,
  meta: Nullable.t<WebCodecs.audioChunkMetadata>,
) =>
  if state.running {
    switch meta->Nullable.toOption {
    | Some(meta) =>
      switch meta.decoderConfig {
      | Some(decoderConfig) =>
        if state.audioDecoderConfig->Option.isNone {
          state.audioDecoderConfig = Some(decoderConfig)
        }
      | None => ()
      }
    | None => ()
    }
    let byteLength = chunk->WebCodecs.audioChunkByteLength
    let bytes = Uint8Array.fromLength(byteLength)
    chunk->WebCodecs.audioCopyTo(bytes)
    state.audioRing = SampleRing.push(
      state.audioRing,
      {
        timestampUs: chunk->WebCodecs.audioChunkTimestamp -.
        state.audioEpochUs->Option.getOr(0.),
        durationUs: chunk->WebCodecs.audioChunkDuration->Nullable.toOption->Option.getOr(0.),
        byteLength,
        payload: bytes,
      },
    )
  }

let ensureAudioEncoder = async (state, data: WebCodecs.audioData) =>
  if state.audioEncoder->Option.isNone && !state.audioConfiguring {
    state.audioConfiguring = true
    let sampleRate = data->WebCodecs.audioDataSampleRate
    let channels = data->WebCodecs.audioDataChannels
    let candidates = [("aac", "mp4a.40.2"), ("opus", "opus")]
    let rec probe = async index =>
      switch candidates->Array.get(index) {
      | None => None
      | Some((container, codec)) => {
          let config: WebCodecs.audioEncoderConfig = {
            codec,
            sampleRate,
            numberOfChannels: channels,
            bitrate: 128_000.,
          }
          let supported = try {
            (await WebCodecs.isAudioConfigSupported(config)).supported
          } catch {
          | _ => false
          }
          supported ? Some((container, config)) : await probe(index + 1)
        }
      }
    switch await probe(0) {
    | None => () // no encodable audio codec: clips stay silent
    | Some((container, config)) =>
      if state.running {
        try {
          let encoder = WebCodecs.makeAudioEncoder({
            output: (chunk, meta) => onAudioChunk(state, chunk, meta),
            error: _ => (),
          })
          encoder->WebCodecs.configureAudio(config)
          state.audioEncoder = Some(encoder)
          state.audioContainerCodec = Some(container)
          state.audioCodecString = Some(config.codec)
          state.audioSampleRate = sampleRate
          state.audioChannels = channels
        } catch {
        | _ => ()
        }
      }
    }
  }

let startAudio = (state, stream) =>
  if WebCodecs.hasAudioEncoder() && WebCodecs.hasTrackProcessor() {
    switch stream->UserMedia.getAudioTracks->Array.get(0) {
    | None => () // camera-only stream (mic denied or not requested)
    | Some(track) =>
      try {
        let reader =
          WebCodecs.makeTrackProcessor({track: track})->WebCodecs.readable->WebCodecs.getReader
        state.audioReader = Some(reader)
        let rec loop = async () => {
          let result = await reader->WebCodecs.read
          let value = result.value->Nullable.toOption
          if state.running && !result.done_ {
            switch value {
            | Some(data) => {
                // Anchor the audio clock to the video timeline on first sight.
                if state.audioEpochUs->Option.isNone {
                  state.audioEpochUs = Some(
                    data->WebCodecs.audioDataTimestamp -. Math.max(state.lastVideoTsUs, 0.),
                  )
                }
                await ensureAudioEncoder(state, data)
                switch state.audioEncoder {
                | Some(encoder) =>
                  if !state.flushing && encoder->WebCodecs.audioEncodeQueueSize <= maxAudioQueue {
                    try {
                      encoder->WebCodecs.encodeAudio(data)
                    } catch {
                    | _ => ()
                    }
                  }
                | None => ()
                }
                data->WebCodecs.closeAudioData
                await loop()
              }
            | None => await loop()
            }
          } else {
            // Stopped or track ended: release the last frame we were handed.
            value->Option.forEach(data => data->WebCodecs.closeAudioData)
          }
        }
        loop()->ignore
      } catch {
      | _ => () // MSTP construction failed: silent clips
      }
    }
  }

let takeClip = async (state, ~seconds: option<float>=?): result<
  CaptureSession.clip,
  CaptureSession.clipError,
> =>
  switch (state.videoEncoder, state.videoCodec, state.running) {
  | (Some(encoder), Some(codec), true) => {
      // Flush so the freshest frames land in the ring. Safari's flush can
      // stall, so race a timeout and proceed with whatever is ringed. The
      // flushing flag pauses frame feeding meanwhile (see state comment).
      state.flushing = true
      let flushDone = (
        async () => {
          try {
            await encoder->WebCodecs.flush
          } catch {
          | _ => ()
          }
          switch state.audioEncoder {
          | Some(audioEncoder) =>
            try {
              await audioEncoder->WebCodecs.flushAudio
            } catch {
            | _ => ()
            }
          | None => ()
          }
          true
        }
      )()
      let flushTimeout = Promise.make((resolve, _reject) => {
        let _ = setTimeout(() => resolve(false), flushTimeoutMs)
      })
      let _ = await Promise.race([flushDone, flushTimeout])
      state.flushing = false
      // The ring value is an immutable snapshot: encoding continues into
      // state.ring while we mux this one.
      // Never longer than the ring holds; a trim request only shortens.
      let windowUs = switch seconds {
      | Some(value) => Math.min(targetDurationUs, Math.max(1., value) *. 1_000_000.)
      | None => targetDurationUs
      }
      switch ClipRing.takeClip(state.ring, ~targetDurationUs=windowUs) {
      | None => Error(CaptureSession.BufferEmpty)
      | Some(clip) => {
          let videoChunks = clip.chunks->Array.map(chunk => {
            MuxBindings.bytes: chunk.payload,
            timestampUs: chunk.timestampUs,
            durationUs: chunk.durationUs,
            isKey: chunk.isKey,
          })
          let video: MuxBindings.muxVideoConfig = {
            codec,
            width: state.width,
            height: state.height,
            description: ?state.videoDecoderConfig->Option.flatMap(config => config.description),
          }
          let audioInRange =
            state.audioRing->SampleRing.selectRange(
              ~fromUs=clip.baseUs,
              ~toUs=clip.baseUs +. clip.durationUs,
            )
          let audio = switch (
            state.audioContainerCodec,
            state.audioCodecString,
            audioInRange->Array.length > 0,
          ) {
          | (Some(containerCodec), Some(audioCodec), true) =>
            Some({
              MuxBindings.containerCodec,
              codec: audioCodec,
              sampleRate: state.audioSampleRate,
              numberOfChannels: state.audioChannels,
              description: ?state.audioDecoderConfig->Option.flatMap(config => config.description),
            })
          | _ => None
          }
          let audioChunks = audio->Option.isSome
            ? audioInRange->Array.map(chunk => {
                MuxBindings.bytes: chunk.payload,
                timestampUs: chunk.timestampUs,
                durationUs: chunk.durationUs,
                isKey: true, // every AAC/Opus frame stands alone
              })
            : []
          switch await MuxBindings.muxClip(~video, ~videoChunks, ~audio, ~audioChunks) {
          | Ok(blob) =>
            Ok({
              CaptureSession.blob: blob,
              mimeType: "video/mp4",
              durationSeconds: clip.durationUs /. 1_000_000.,
              hasAudio: audio->Option.isSome,
            })
          | Error(message) => Error(CaptureSession.MuxFailed(message))
          }
        }
      }
    }
  | _ => Error(CaptureSession.NotStarted)
  }

let stop = state =>
  if state.running {
    state.running = false
    settleStart(state, Error(CaptureSession.VideoPlaybackFailed("Capture stopped")))
    switch (state.video, state.rvfc) {
    | (Some(video), Some(handle)) =>
      try {
        video->WebCodecs.cancelVideoFrameCallback(handle)
      } catch {
      | _ => ()
      }
    | _ => ()
    }
    state.rvfc = None
    state.videoEncoder->Option.forEach(encoder =>
      try {
        encoder->WebCodecs.closeEncoder
      } catch {
      | _ => () // closing a closed encoder throws
      }
    )
    state.videoEncoder = None
    state.audioEncoder->Option.forEach(encoder =>
      try {
        encoder->WebCodecs.closeAudioEncoder
      } catch {
      | _ => ()
      }
    )
    state.audioEncoder = None
    state.audioReader->Option.forEach(reader => reader->WebCodecs.cancelReader->ignore)
    state.audioReader = None
    state.video->Option.forEach(video => {
      video->UserMedia.setSrcObject(Nullable.null)
      video->removeElement
    })
    state.video = None
    state.statusTimer->Option.forEach(timer => clearInterval(timer))
    state.statusTimer = None
    state.ring = ClipRing.make(~keepDurationUs, ~maxBytes=maxRingBytes)
    state.audioRing = SampleRing.make(~keepDurationUs)
    state.audioEpochUs = None
    state.lastVideoTsUs = 0.
  }

let capabilities = (): CaptureSession.capabilities => {
  let missing = if !WebCodecs.hasRvfc() {
    Some("requestVideoFrameCallback")
  } else if !WebCodecs.hasVideoFrame() {
    Some("VideoFrame")
  } else if !WebCodecs.hasVideoEncoder() {
    Some("VideoEncoder")
  } else {
    None
  }
  {
    canClip: missing->Option.isNone,
    hasAudio: WebCodecs.hasAudioEncoder() && WebCodecs.hasTrackProcessor(),
    detail: missing->Option.map(name => name ++ " is not supported in this browser"),
  }
}

let start = async (state, ~onStatus: CaptureSession.status => unit, stream) =>
  if state.running {
    Error(CaptureSession.AlreadyStarted)
  } else if !capabilities().canClip {
    Error(CaptureSession.Unsupported)
  } else {
    state.running = true
    state.frameRate = stream->UserMedia.videoFrameRate->Option.getOr(30.)
    let video = createElement("video")
    video->setMuted(true)
    video->setPlaysInline(true)
    video
    ->style
    ->setCssText(
      "position:fixed;left:0;bottom:0;width:1px;height:1px;opacity:0.01;pointer-events:none;z-index:-1",
    )
    video->UserMedia.setSrcObject(Nullable.make(stream))
    documentBody->appendChild(video)
    state.video = Some(video)
    let playResult = try {
      await video->play
      Ok()
    } catch {
    | exn => Error(MuxBindings.errorToMessage(exn))
    }
    switch playResult {
    | Error(message) => {
        stop(state)
        Error(CaptureSession.VideoPlaybackFailed(message))
      }
    | Ok() => {
        let rec onFrame = (now: float, metadata: WebCodecs.frameMetadata) =>
          if state.running {
            // Re-arm first so a thrown error cannot kill the loop.
            state.rvfc = Some(video->WebCodecs.requestVideoFrameCallback(onFrame))
            switch state.videoEncoder {
            | Some(encoder) => encodeFrame(state, video, encoder, now)
            | None =>
              if !state.videoConfiguring {
                state.videoConfiguring = true
                configureVideo(state, metadata)->ignore
              }
            }
          }
        state.rvfc = Some(video->WebCodecs.requestVideoFrameCallback(onFrame))
        startAudio(state, stream)
        state.statusTimer = Some(
          setInterval(() => {
            if state.running {
              onStatus({
                bufferedSeconds: ClipRing.bufferedDurationUs(state.ring) /. 1_000_000.,
                targetSeconds,
                totalBytes: ClipRing.totalBytes(state.ring) + SampleRing.totalBytes(state.audioRing),
                droppedFrames: state.droppedFrames,
              })
            }
          }, 1000),
        )
        let firstChunk = Promise.make((resolve, _reject) => {
          state.resolveStart = Some(resolve)
        })
        let watchdog = Promise.make((resolve, _reject) => {
          let _ = setTimeout(
            () =>
              resolve(
                Error(CaptureSession.VideoPlaybackFailed("Timed out waiting for camera frames")),
              ),
            firstFrameTimeoutMs,
          )
        })
        await Promise.race([firstChunk, watchdog])
      }
    }
  }

let make = (~onStatus: CaptureSession.status => unit): CaptureSession.t => {
  let state = {
    running: false,
    video: None,
    rvfc: None,
    videoEncoder: None,
    videoCodec: None,
    videoDecoderConfig: None,
    videoConfiguring: false,
    width: 0,
    height: 0,
    frameRate: 30.,
    lastKeyUs: Float.Constants.negativeInfinity,
    lastVideoTsUs: 0.,
    audioEpochUs: None,
    ring: ClipRing.make(~keepDurationUs, ~maxBytes=maxRingBytes),
    audioRing: SampleRing.make(~keepDurationUs),
    audioEncoder: None,
    audioContainerCodec: None,
    audioCodecString: None,
    audioConfiguring: false,
    audioDecoderConfig: None,
    audioSampleRate: 48000.,
    audioChannels: 1,
    audioReader: None,
    droppedFrames: 0,
    flushing: false,
    statusTimer: None,
    resolveStart: None,
  }
  {
    capabilities,
    start: stream => start(state, ~onStatus, stream),
    takeClip: (~seconds=?) => takeClip(state, ~seconds?),
    stop: () => stop(state),
  }
}
