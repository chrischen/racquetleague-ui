import { describe, expect, it } from "vitest";
import * as SolverTypes from "../../src/lib/rating/solver/SolverTypes.re.mjs";

describe("violation serialization", () => {
  it("round-trips every violation kind", () => {
    const all = [
      { TAG: "AntiTeam", groupIndex: 2, playerIds: ["a", "b"] },
      { TAG: "PartnerPool", teamPlayerIds: ["c", "d"] },
      { TAG: "RequiredPlayerUnseated", playerId: "e" },
      { TAG: "BackToBackBye", playerId: "f" },
      { TAG: "NotGenderMixed", teamPlayerIds: ["g", "h"] },
    ];
    all.forEach((violation) => {
      // Through real JSON text, as persistence does.
      const wire = JSON.parse(JSON.stringify(SolverTypes.toJson(violation)));
      expect(SolverTypes.fromJson(wire)).toEqual(violation);
    });
  });

  it("rejects malformed payloads instead of fabricating warnings", () => {
    expect(SolverTypes.fromJson({ kind: "nonsense" })).toBeUndefined();
    expect(SolverTypes.fromJson({ kind: "backToBackBye" })).toBeUndefined();
    expect(SolverTypes.fromJson("not an object")).toBeUndefined();
  });
});
