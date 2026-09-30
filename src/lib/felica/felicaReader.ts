// FeliCa (Suica, PASMO, nanaco, …) card IDs from a Sony RC-S300 over WebUSB.
//
// The RC-S300 exposes two USB interfaces: #0 is a standard CCID smart-card
// interface (macOS's usbsmartcardreaderd holds it exclusively, and WebUSB
// refuses the smart-card class anyway) and #1 is a vendor interface that
// speaks the same CCID message framing. We claim #1 and send CCID
// PC_to_RDR_Escape messages carrying Sony's transparent-session pseudo-APDUs
// (CLA FF, INS 50). Byte sequences verified against a real RC-S300/P
// (054C:0DC9): session commands answer C0 03 00 90 00 + 90 00; a FeliCa
// polling transceive answers C0 03 02 64 01 ("no response") with no card.
//
// Chrome-family browsers only (WebUSB); secure context (https or localhost).
// Needs one user gesture to grant the device (requestReader); afterwards
// grantedReader() finds it again without a prompt.

// ── Minimal WebUSB typings (the project has no @types/w3c-web-usb) ──────────
type USBDirection = "in" | "out";
interface USBEndpoint { endpointNumber: number; direction: USBDirection; type: string }
interface USBAlternateInterface { interfaceClass: number; endpoints: USBEndpoint[] }
interface USBInterface { interfaceNumber: number; alternate: USBAlternateInterface }
interface USBConfiguration { configurationValue: number; interfaces: USBInterface[] }
interface USBInTransferResult { data?: DataView; status: string }
interface USBOutTransferResult { bytesWritten: number; status: string }
export interface USBDevice {
  vendorId: number;
  productId: number;
  productName?: string;
  serialNumber?: string;
  opened: boolean;
  configuration: USBConfiguration | null;
  open(): Promise<void>;
  close(): Promise<void>;
  selectConfiguration(value: number): Promise<void>;
  claimInterface(n: number): Promise<void>;
  releaseInterface(n: number): Promise<void>;
  transferOut(endpoint: number, data: BufferSource): Promise<USBOutTransferResult>;
  transferIn(endpoint: number, length: number): Promise<USBInTransferResult>;
}
interface USB extends EventTarget {
  getDevices(): Promise<USBDevice[]>;
  requestDevice(options: { filters: { vendorId: number; productId?: number }[] }): Promise<USBDevice>;
}
const usb = (): USB | undefined =>
  typeof navigator !== "undefined" ? (navigator as unknown as { usb?: USB }).usb : undefined;

// ── Device identity ─────────────────────────────────────────────────────────
const SONY = 0x054c;
const RC_S300 = [0x0dc8 /* RC-S300/S */, 0x0dc9 /* RC-S300/P */];
const FILTERS = RC_S300.map((productId) => ({ vendorId: SONY, productId }));
const isRcs300 = (d: USBDevice) => d.vendorId === SONY && RC_S300.includes(d.productId);

export function isSupported(): boolean {
  return usb() !== undefined;
}

/** A previously granted reader, without prompting. */
export async function grantedReader(): Promise<USBDevice | null> {
  const api = usb();
  if (!api) return null;
  return (await api.getDevices()).find(isRcs300) ?? null;
}

/** Calls back when a (previously granted) RC-S300 is plugged in; returns an unsubscribe. */
export function onReaderConnected(callback: (device: USBDevice) => void): () => void {
  const api = usb();
  if (!api) return () => undefined;
  const listener = (event: Event) => {
    const device = (event as unknown as { device: USBDevice }).device;
    if (isRcs300(device)) callback(device);
  };
  api.addEventListener("connect", listener);
  return () => api.removeEventListener("connect", listener);
}

/** Prompt for the reader. Must run inside a user gesture (a click). */
export async function requestReader(): Promise<USBDevice> {
  const api = usb();
  if (!api) throw new Error("WebUSB is not available in this browser (use Chrome or Edge)");
  return api.requestDevice({ filters: FILTERS });
}

// ── Protocol ────────────────────────────────────────────────────────────────
// Transparent-session pseudo-APDUs (PC/SC Part 3 supplement layout, Sony INS 50).
const END_SESSION = [0xff, 0x50, 0x00, 0x00, 0x02, 0x82, 0x00, 0x00];
const START_SESSION = [0xff, 0x50, 0x00, 0x00, 0x02, 0x81, 0x00, 0x00];
const RF_OFF = [0xff, 0x50, 0x00, 0x00, 0x02, 0x83, 0x00, 0x00];
const RF_ON = [0xff, 0x50, 0x00, 0x00, 0x02, 0x84, 0x00, 0x00];
const SELECT_FELICA = [0xff, 0x50, 0x00, 0x02, 0x04, 0x8f, 0x02, 0x03, 0x00, 0x00]; // Type F, 212 kbps

// FeliCa Polling: length 06, command 00, system code 0003 (transit IC),
// request code 01 (return the system code), time slot 0. Polling for 0003
// rather than the FFFF wildcard is what makes an iPhone answer with its
// Express Transit card (Suica, PASMO, …) without Face ID — a wildcard (or any
// other system code) makes it open Wallet on the default payment card. The
// cost: plastic cards without a transit system (Edy, nanaco, WAON) stay silent.
const FELICA_POLL = [0x06, 0x00, 0x00, 0x03, 0x01, 0x00];
const POLL_BODY = [
  0x5f, 0x46, 0x04, 0xa0, 0x86, 0x01, 0x00, // timer: 100 000 µs
  0x95, 0x82, 0x00, FELICA_POLL.length, ...FELICA_POLL, // transceive
];
// Short APDU: FF 50 00 01 Lc <body> Le(00). (Extended length with a 2-byte
// Le is rejected with 67 00 by the RC-S300.)
const POLL = [0xff, 0x50, 0x00, 0x01, POLL_BODY.length, ...POLL_BODY, 0x00];

const PC_TO_RDR_ESCAPE = 0x6b;
const RDR_TO_PC_ESCAPE = 0x83;
const TRANSFER_TIMEOUT_MS = 1500;

export type FelicaCard = {
  idm: string; // 16 hex digits, upper case
  pmm: string;
  systemCode: string | null; // 4 hex digits, e.g. "0003" for transit IC (Suica, PASMO, …)
};

const hex = (bytes: Uint8Array) =>
  Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("").toUpperCase();

/** Parse a transceive reply's data: the card's answer is the 0x97 data object. */
export function parsePollReply(data: Uint8Array): FelicaCard | null {
  for (let i = 0; i + 1 < data.length; i++) {
    if (data[i] !== 0x97) continue;
    // BER length: short form, or 81 LL.
    let len = data[i + 1];
    let at = i + 2;
    if (len === 0x81) {
      len = data[i + 2];
      at = i + 3;
    }
    const answer = data.subarray(at, at + len);
    // FeliCa polling response: [len][01][IDm 8][PMm 8][system code 2]?
    if (answer.length >= 18 && answer[1] === 0x01) {
      return {
        idm: hex(answer.subarray(2, 10)),
        pmm: hex(answer.subarray(10, 18)),
        systemCode: answer.length >= 20 ? hex(answer.subarray(18, 20)) : null,
      };
    }
    return null;
  }
  return null;
}

const withTimeout = <T>(p: Promise<T>, ms: number, what: string) =>
  Promise.race([
    p,
    new Promise<T>((_, reject) => setTimeout(() => reject(new Error(`${what} timed out`)), ms)),
  ]);

export class Rcs300 {
  private seq = 0;
  private outEp = 0;
  private inEp = 0;
  private iface = -1;

  constructor(readonly device: USBDevice) {}

  get name(): string {
    return this.device.productName || "RC-S300";
  }

  /** Open the device, claim the vendor interface, start a FeliCa session. */
  async open(): Promise<void> {
    const d = this.device;
    if (!d.opened) await d.open();
    if (!d.configuration) await d.selectConfiguration(1);
    const vendor = d.configuration?.interfaces.find((i) => i.alternate.interfaceClass === 0xff);
    if (!vendor) throw new Error("RC-S300 vendor interface not found");
    this.iface = vendor.interfaceNumber;
    await d.claimInterface(this.iface);
    const ep = (dir: USBDirection) =>
      vendor.alternate.endpoints.find((e) => e.direction === dir && e.type === "bulk")?.endpointNumber;
    const out = ep("out");
    const inn = ep("in");
    if (out === undefined || inn === undefined) throw new Error("RC-S300 bulk endpoints not found");
    this.outEp = out;
    this.inEp = inn;
    await this.escape(END_SESSION); // a previous page may have left one open
    await this.escape(START_SESSION);
    await this.escape(RF_OFF);
    await this.escape(RF_ON);
    await this.escape(SELECT_FELICA);
  }

  /** One polling round: the card on the reader, or null. */
  async poll(): Promise<FelicaCard | null> {
    return parsePollReply(await this.escape(POLL));
  }

  async close(): Promise<void> {
    try {
      if (this.iface >= 0) {
        await this.escape(RF_OFF).catch(() => undefined);
        await this.escape(END_SESSION).catch(() => undefined);
        await this.device.releaseInterface(this.iface).catch(() => undefined);
      }
    } finally {
      this.iface = -1;
      await this.device.close().catch(() => undefined);
    }
  }

  /** CCID PC_to_RDR_Escape → RDR_to_PC_Escape; returns the reply's data. */
  private async escape(payload: number[]): Promise<Uint8Array> {
    this.seq = (this.seq + 1) & 0xff;
    const n = payload.length;
    const msg = new Uint8Array(10 + n);
    msg.set([PC_TO_RDR_ESCAPE, n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff, (n >>> 24) & 0xff, 0x00, this.seq, 0, 0, 0]);
    msg.set(payload, 10);
    await withTimeout(this.device.transferOut(this.outEp, msg), TRANSFER_TIMEOUT_MS, "reader write");
    const res = await withTimeout(this.device.transferIn(this.inEp, 512), TRANSFER_TIMEOUT_MS, "reader read");
    if (!res.data || res.data.byteLength < 10) throw new Error("short reply from the reader");
    const reply = new Uint8Array(res.data.buffer, res.data.byteOffset, res.data.byteLength);
    if (reply[0] !== RDR_TO_PC_ESCAPE) throw new Error(`unexpected reply 0x${reply[0].toString(16)}`);
    return reply.subarray(10);
  }
}

/**
 * Poll the reader until `signal` aborts. Reports each card ARRIVAL once
 * (a card left on the reader is not re-reported); a card counts as removed
 * after two empty polls in a row, so the same card can be tapped again.
 */
export async function watchCards(
  device: USBDevice,
  onCard: (card: FelicaCard) => void,
  signal: AbortSignal,
  intervalMs = 250,
): Promise<void> {
  const reader = new Rcs300(device);
  await reader.open();
  let current: string | null = null;
  let misses = 0;
  try {
    while (!signal.aborted) {
      const card = await reader.poll();
      if (card) {
        misses = 0;
        if (card.idm !== current) {
          current = card.idm;
          onCard(card);
        }
      } else if (current && ++misses >= 2) {
        current = null;
      }
      await new Promise((r) => setTimeout(r, intervalMs));
    }
  } finally {
    await reader.close();
  }
}
