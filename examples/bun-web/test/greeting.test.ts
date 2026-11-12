import { describe, expect, test } from "bun:test";
import { greeting } from "../src/greeting";

describe("greeting", () => {
  test("greets the world without a name", () => {
    expect(greeting()).toBe("Hello, world!");
    expect(greeting("   ")).toBe("Hello, world!");
  });

  test("trims and greets a name", () => {
    expect(greeting("  Meg ")).toBe("Hello, Meg!");
  });
});
