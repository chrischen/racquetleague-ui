// Re-encodes a clip's video track cropped to a rectangle, for the analysis
// upload: the server's ball detector resizes whatever it receives to 512x288,
// so sending only the court region both cuts its per-frame cost and lands the
// court on ~2-3x more detector pixels, while dropping the wide-angle periphery
// that produced false detections. Hardware decode + encode via WebCodecs;
// timestamps are preserved, so the kiosk's frame timeline stays valid and the
// results map straight back onto the full clip by adding the crop origin.
//
// TypeScript (not ReScript %raw) for the same reason as muxLoader.ts: the
// async decoder/encoder plumbing is natural here and the mux helper is reused.

import { muxClip, type MuxChunk } from "./muxLoader";

export type CropRect = { x: number; y: number; width: number; height: number };

export type EncodedVideo = {
  codec: string;
  width: number;
  height: number;
  description?: Uint8Array;
  chunks: MuxChunk[];
};

const KEYFRAME_INTERVAL_US = 2_000_000;

// H.264 level ladders by picture size (mirrors LocalRingCapture.configureVideo).
function codecCandidates(width: number, height: number): string[] {
  const pixels = width * height;
  if (pixels > 1920 * 1088) return ["avc1.640033", "avc1.640034", "avc1.4d0033"];
  if (pixels > 1280 * 720) return ["avc1.64002a", "avc1.640028", "avc1.4d002a", "avc1.4d0028", "avc1.42e028"];
  return ["avc1.4d001f", "avc1.42e01f", "avc1.640028"];
}

function medianDeltaUs(chunks: MuxChunk[]): number {
  const deltas: number[] = [];
  for (let i = 1; i < chunks.length; i++) deltas.push(chunks[i].timestampUs - chunks[i - 1].timestampUs);
  if (deltas.length === 0) return 33_333;
  deltas.sort((a, b) => a - b);
  return deltas[Math.floor(deltas.length / 2)] || 33_333;
}

const even = (v: number) => Math.max(0, Math.floor(v) - (Math.floor(v) % 2));

const waitUntil = (ready: () => boolean) =>
  new Promise<void>((resolve) => {
    const tick = (): void => {
      if (ready()) resolve();
      else setTimeout(tick, 4);
    };
    tick();
  });

export function isAvailable(): boolean {
  return typeof VideoDecoder === "function" && typeof VideoEncoder === "function" && typeof VideoFrame === "function";
}

export async function cropClip(source: EncodedVideo, crop: CropRect): Promise<Blob> {
  if (!isAvailable()) throw new Error("WebCodecs decode/encode is not available in this browser");
  if (source.chunks.length === 0) throw new Error("clip has no video chunks");

  // 4:2:0 chroma subsampling: origin and size must be even.
  const rect = {
    x: Math.min(even(crop.x), even(source.width - 2)),
    y: Math.min(even(crop.y), even(source.height - 2)),
    width: 0,
    height: 0,
  };
  rect.width = Math.max(2, Math.min(even(crop.width), even(source.width - rect.x)));
  rect.height = Math.max(2, Math.min(even(crop.height), even(source.height - rect.y)));

  const fps = 1e6 / medianDeltaUs(source.chunks);
  const bitrate = Math.min(
    24_000_000,
    Math.max(1_500_000, (6_000_000 * (rect.width * rect.height)) / (1920 * 1080) * Math.max(1, fps / 30)),
  );

  let encoderConfig: VideoEncoderConfig | null = null;
  for (const codec of codecCandidates(rect.width, rect.height)) {
    const candidate: VideoEncoderConfig = {
      codec,
      width: rect.width,
      height: rect.height,
      bitrate,
      framerate: fps,
      latencyMode: "realtime",
      avc: { format: "avc" },
      hardwareAcceleration: "no-preference",
    };
    try {
      if ((await VideoEncoder.isConfigSupported(candidate)).supported) {
        encoderConfig = candidate;
        break;
      }
    } catch {
      /* try the next one */
    }
  }
  if (!encoderConfig) throw new Error(`no H.264 encoder config for ${rect.width}x${rect.height}`);

  const out: MuxChunk[] = [];
  let outDescription: Uint8Array | undefined;
  let failure: unknown = null;
  let lastKeyUs = -Infinity;
  let useCanvas = false;
  let canvas: OffscreenCanvas | null = null;
  let ctx: OffscreenCanvasRenderingContext2D | null = null;

  const encoder = new VideoEncoder({
    output: (chunk, meta) => {
      if (meta?.decoderConfig?.description && !outDescription) {
        const d = meta.decoderConfig.description;
        outDescription = d instanceof ArrayBuffer ? new Uint8Array(d) : new Uint8Array(d.buffer, d.byteOffset, d.byteLength);
      }
      const bytes = new Uint8Array(chunk.byteLength);
      chunk.copyTo(bytes);
      out.push({ bytes, timestampUs: chunk.timestamp, durationUs: chunk.duration ?? 0, isKey: chunk.type === "key" });
    },
    error: (e) => {
      failure = failure ?? e;
    },
  });
  encoder.configure(encoderConfig);

  const cropFrame = (frame: VideoFrame): VideoFrame => {
    if (!useCanvas) {
      try {
        // Zero-copy crop where the engine supports it.
        return new VideoFrame(frame, { visibleRect: rect });
      } catch {
        useCanvas = true;
      }
    }
    if (!canvas || !ctx) {
      canvas = new OffscreenCanvas(rect.width, rect.height);
      ctx = canvas.getContext("2d");
      if (!ctx) throw new Error("OffscreenCanvas 2d context unavailable");
    }
    ctx.drawImage(frame, rect.x, rect.y, rect.width, rect.height, 0, 0, rect.width, rect.height);
    return new VideoFrame(canvas, { timestamp: frame.timestamp, duration: frame.duration ?? undefined });
  };

  const decoder = new VideoDecoder({
    output: (frame) => {
      try {
        const keyFrame = frame.timestamp - lastKeyUs >= KEYFRAME_INTERVAL_US;
        if (keyFrame) lastKeyUs = frame.timestamp;
        const cropped = cropFrame(frame);
        try {
          encoder.encode(cropped, { keyFrame });
        } finally {
          cropped.close();
        }
      } catch (e) {
        failure = failure ?? e;
      } finally {
        frame.close();
      }
    },
    error: (e) => {
      failure = failure ?? e;
    },
  });
  decoder.configure({
    codec: source.codec,
    codedWidth: source.width,
    codedHeight: source.height,
    description: source.description,
    optimizeForLatency: true,
  });

  try {
    for (const c of source.chunks) {
      if (failure) break;
      await waitUntil(() => decoder.decodeQueueSize < 8 && encoder.encodeQueueSize < 8);
      decoder.decode(
        new EncodedVideoChunk({
          type: c.isKey ? "key" : "delta",
          timestamp: c.timestampUs,
          duration: c.durationUs > 0 ? c.durationUs : undefined,
          data: c.bytes,
        }),
      );
    }
    if (!failure) await decoder.flush();
    if (!failure) await encoder.flush();
  } finally {
    try { decoder.close(); } catch { /* already closed */ }
    try { encoder.close(); } catch { /* already closed */ }
  }
  if (failure) throw failure instanceof Error ? failure : new Error(String(failure));
  if (out.length === 0) throw new Error("crop produced no frames");

  return muxClip(
    { codec: encoderConfig.codec, width: rect.width, height: rect.height, description: outDescription },
    out,
    undefined,
    [],
  );
}
