import { describe, expect, it } from "vitest";
import { parsePollReply } from "../../src/lib/felica/felicaReader";

// Transparent-exchange reply data (after the 10-byte CCID header):
//   C0 03 <status> <SW1 SW2>   status object
//   97 <len> <card response>   the FeliCa card's own answer
//   90 00                      APDU status
const bytes = (hex: string) => Uint8Array.from(hex.replace(/\s+/g, "").match(/../g)!.map((h) => parseInt(h, 16)));

describe("parsePollReply", () => {
  it("extracts IDm, PMm and system code from a polling response", () => {
    // FeliCa polling response: len 14, code 01, IDm, PMm, system code 0003 (Suica)
    const reply = bytes("C0 03 00 90 00  97 14  14 01 0123456789ABCDEF 0510 0F01 4B24 2B8B 0003  90 00");
    expect(parsePollReply(reply)).toEqual({
      idm: "0123456789ABCDEF",
      pmm: "05100F014B242B8B",
      systemCode: "0003",
    });
  });

  it("handles a response without the system code (request code 00)", () => {
    const reply = bytes("C0 03 00 90 00  97 12  12 01 0123456789ABCDEF 0510 0F01 4B24 2B8B  90 00");
    expect(parsePollReply(reply)?.systemCode).toBeNull();
  });

  it("accepts the long-form BER length (81 LL)", () => {
    const reply = bytes("C0 03 00 90 00  97 81 14  14 01 0011223344556677 8899AABBCCDDEEFF FE00  90 00");
    expect(parsePollReply(reply)).toMatchObject({ idm: "0011223344556677", systemCode: "FE00" });
  });

  it("returns null for the reader's real no-card answer", () => {
    // captured from an RC-S300/P with nothing on it: no response (64 01)
    expect(parsePollReply(bytes("C0 03 02 64 01 90 00"))).toBeNull();
  });

  it("returns null for a non-polling answer", () => {
    expect(parsePollReply(bytes("C0 03 00 90 00  97 03  03 07 00  90 00"))).toBeNull();
  });
});
