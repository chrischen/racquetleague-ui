// Lazily loads mediabunny and muxes pre-encoded WebCodecs chunks into a
// fast-start MP4. Written in TypeScript rather than a ReScript %raw so that
// Vite sees the dynamic import statically and emits mediabunny as its own
// lazy chunk (same reasoning as src/lib/rating/solver/highsLoader.ts).
//
// The API speaks plain byte/timestamp records — no WebCodecs or mediabunny
// types leak out — so swapping the muxer implementation only touches this
// file. Timestamp conversion also lives only here: callers use microseconds
// (WebCodecs convention), mediabunny wants seconds.

export type MuxChunk = {
  bytes: Uint8Array;
  timestampUs: number; // already rebased: first chunk of a clip is 0
  durationUs: number; // 0 means unknown; a delta to the next chunk is used
  isKey: boolean;
};

export type MuxVideoConfig = {
  codec: string; // e.g. "avc1.4d001f"
  width: number;
  height: number;
  description?: Uint8Array; // avcC from EncodedVideoChunkMetadata.decoderConfig
};

export type MuxAudioConfig = {
  containerCodec: "aac" | "opus";
  codec: string; // e.g. "mp4a.40.2"
  sampleRate: number;
  numberOfChannels: number;
  description?: Uint8Array; // AudioSpecificConfig for AAC
};

type Mediabunny = typeof import("mediabunny");

let mediabunnyPromise: Promise<Mediabunny> | null = null;

// Cached like loadHighs; un-cache on failure so a flaky network can retry.
function loadMediabunny(): Promise<Mediabunny> {
  if (!mediabunnyPromise) {
    mediabunnyPromise = import("mediabunny").catch((error) => {
      mediabunnyPromise = null;
      throw error;
    });
  }
  return mediabunnyPromise;
}

export async function muxClip(
  video: MuxVideoConfig,
  videoChunks: MuxChunk[],
  audio: MuxAudioConfig | undefined,
  audioChunks: MuxChunk[],
): Promise<Blob> {
  const {
    Output,
    Mp4OutputFormat,
    BufferTarget,
    EncodedVideoPacketSource,
    EncodedAudioPacketSource,
    EncodedPacket,
  } = await loadMediabunny();

  const target = new BufferTarget();
  const output = new Output({
    format: new Mp4OutputFormat({ fastStart: "in-memory" }),
    target,
  });

  const videoSource = new EncodedVideoPacketSource("avc");
  output.addVideoTrack(videoSource);

  const audioSource =
    audio && audioChunks.length > 0 ? new EncodedAudioPacketSource(audio.containerCodec) : null;
  if (audioSource) output.addAudioTrack(audioSource);

  await output.start();

  type Meta = EncodedVideoChunkMetadata | EncodedAudioChunkMetadata;
  // Method-shorthand signature keeps the param bivariant so both packet
  // sources satisfy it despite their differing metadata dictionaries.
  type PacketSink = { add(packet: InstanceType<typeof EncodedPacket>, meta?: Meta): Promise<void> };

  const addAll = async (
    source: PacketSink,
    chunks: MuxChunk[],
    meta: Meta,
    fallbackDurationUs: number,
  ) => {
    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i];
      const next = chunks[i + 1];
      const durationUs =
        chunk.durationUs > 0
          ? chunk.durationUs
          : next
            ? next.timestampUs - chunk.timestampUs
            : fallbackDurationUs;
      const packet = new EncodedPacket(
        chunk.bytes,
        chunk.isKey ? "key" : "delta",
        chunk.timestampUs / 1e6,
        Math.max(0, durationUs) / 1e6,
      );
      // Decoder config (avcC / AudioSpecificConfig) rides on the first packet.
      try {
        await source.add(packet, i === 0 ? meta : undefined);
      } catch (error) {
        console.error(
          `[muxLoader] add failed at index ${i}/${chunks.length}: ts=${chunk.timestampUs} prev=${chunks[i - 1]?.timestampUs} isKey=${chunk.isKey}`,
        );
        throw error;
      }
    }
  };

  await addAll(
    videoSource,
    videoChunks,
    {
      decoderConfig: {
        codec: video.codec,
        codedWidth: video.width,
        codedHeight: video.height,
        description: video.description,
      },
    },
    33_333,
  );

  if (audioSource && audio) {
    await addAll(
      audioSource,
      audioChunks,
      {
        decoderConfig: {
          codec: audio.codec,
          sampleRate: audio.sampleRate,
          numberOfChannels: audio.numberOfChannels,
          description: audio.description,
        },
      },
      21_333,
    );
  }

  await output.finalize();
  if (!target.buffer) throw new Error("Muxer produced no output buffer");
  return new Blob([target.buffer], { type: "video/mp4" });
}
