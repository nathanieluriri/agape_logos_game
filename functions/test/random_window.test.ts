import {describe, it, expect} from "@jest/globals";
import {pickWindow} from "../src/services/assignment_service";

// PLAN: this pins only the pure boundary math (Firestore range queries are
// validated on the emulator). File is named *.test.ts (not *_test.ts as the
// plan sketched) so jest.config.js's testMatch picks it up.
describe("pickWindow", () => {
  it("returns a value in [0,1) driven by the rng", () => {
    expect(pickWindow(10, () => 0)).toBe(0);
    expect(pickWindow(10, () => 0.5)).toBeGreaterThanOrEqual(0);
    expect(pickWindow(10, () => 0.999999)).toBeLessThan(1);
  });
});
