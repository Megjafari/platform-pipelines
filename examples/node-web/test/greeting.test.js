import assert from "node:assert/strict";
import { test } from "node:test";
import { greeting } from "../src/greeting.js";

test("greets the world without a name", () => {
  assert.equal(greeting(), "Hello, world!");
  assert.equal(greeting("   "), "Hello, world!");
});

test("trims and greets a name", () => {
  assert.equal(greeting("  Meg "), "Hello, Meg!");
});
