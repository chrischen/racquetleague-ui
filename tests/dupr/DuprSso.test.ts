// Reading the message DUPR's SSO iframe posts back.
//
// This runs on whatever the page receives, so the origin check is the whole
// security boundary: anything on the page can call postMessage, and a
// forged message would otherwise hand the server a token of someone else's
// choosing. Only the two tokens are taken — the DUPR id and ratings in the
// payload are ignored, because the server asks DUPR who the token belongs to.
import { describe, expect, it } from "vitest";
import * as DuprSso from "../../src/lib/DuprSso.re.mjs";

const SSO = "https://uat.dupr.gg/login-external-app/abc123";
const ORIGIN = "https://uat.dupr.gg";

const parse = (origin: string, data: unknown) =>
  DuprSso.parseMessage(ORIGIN, origin, data);

// Melange/ReScript compile a no-payload variant to a string and a payload
// variant to {TAG, _0}.
const isIgnored = (r: any) => r === "Ignored";
const isMalformed = (r: any) => r === "Malformed";
const tokens = (r: any) => (r && r.TAG === "Tokens" ? r._0 : undefined);

describe("originOf", () => {
  it("derives the origin to trust from the URL the server gave us", () => {
    expect(DuprSso.originOf(SSO)).toBe(ORIGIN);
    expect(DuprSso.originOf("https://dashboard.dupr.com/login-external-app/x")).toBe(
      "https://dashboard.dupr.com",
    );
  });

  it("reports nothing for a URL it cannot parse", () => {
    expect(DuprSso.originOf("not a url")).toBeUndefined();
  });
});

describe("parseMessage", () => {
  const payload = { userToken: "access-123", refreshToken: "refresh-456" };

  it("takes the tokens from a message DUPR sent", () => {
    const t = tokens(parse(ORIGIN, payload));
    expect(t).toEqual({ accessToken: "access-123", refreshToken: "refresh-456" });
  });

  it("accepts the payload as a JSON string, which some embeds post", () => {
    const t = tokens(parse(ORIGIN, JSON.stringify(payload)));
    expect(t.accessToken).toBe("access-123");
  });

  it("accepts accessToken as a spelling of userToken", () => {
    const t = tokens(parse(ORIGIN, { accessToken: "a", refreshToken: "r" }));
    expect(t.accessToken).toBe("a");
  });

  it("keeps only the tokens, never the id or ratings the page could forge", () => {
    const t = tokens(
      parse(ORIGIN, { ...payload, duprId: "HACKED", id: 1, stats: { doubles: "9.9" } }),
    );
    expect(Object.keys(t).sort()).toEqual(["accessToken", "refreshToken"]);
  });

  it.each([
    ["a lookalike host", "https://uat.dupr.gg.evil.com"],
    ["plain http", "http://uat.dupr.gg"],
    ["our own page", "https://www.pkuru.com"],
    ["a null origin", "null"],
  ])("ignores a well-formed message from %s", (_label, origin) => {
    expect(isIgnored(parse(origin, payload))).toBe(true);
  });

  it.each([
    ["no refresh token", { userToken: "a" }],
    ["no access token", { refreshToken: "r" }],
    ["an empty token", { userToken: "", refreshToken: "r" }],
    ["a whitespace token", { userToken: "   ", refreshToken: "r" }],
    ["a non-JSON string", "hello"],
    ["a number", 42],
    ["null", null],
    ["an array", ["a", "b"]],
  ])("reports a message from DUPR with %s as malformed", (_label, data) => {
    expect(isMalformed(parse(ORIGIN, data))).toBe(true);
  });
});
