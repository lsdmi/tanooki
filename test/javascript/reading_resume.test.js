import { test } from "node:test"
import assert from "node:assert/strict"
import { normalizeText, resolveResumeTarget } from "../../app/javascript/reading_resume.js"

const DIGEST = "0123456789abcdef"
const blocks = [
  { index: 0, text: "Розділ 5" },
  { index: 1, text: "  Ранок почався\n  з дощу. " },
  { index: 2, text: "— Так." },
  { index: 3, text: "Він довго мовчав, а потім пішов до міста." },
  { index: 4, text: "— Так." },
  { index: 5, text: "Кінець." }
]

test("quote hit returns the block that starts with the quote", () => {
  const target = resolveResumeTarget(blocks, { quote: "Він довго мовчав", blockIndex: 1, percent: 10, digest: DIGEST }, DIGEST)

  assert.deepEqual(target, { type: "block", index: 3, via: "quote" })
})

test("quote hit survives an edited chapter whose digest no longer matches", () => {
  const target = resolveResumeTarget(blocks, { quote: "Він довго мовчав", blockIndex: 9, percent: 90, digest: "ffffffffffffffff" }, DIGEST)

  assert.deepEqual(target, { type: "block", index: 3, via: "quote" })
})

test("quote matching ignores whitespace differences", () => {
  const target = resolveResumeTarget(blocks, { quote: "Ранок почався з дощу.", percent: 0 }, DIGEST)

  assert.equal(target.index, 1)
})

test("a repeated quote picks the match nearest the stored index", () => {
  assert.equal(resolveResumeTarget(blocks, { quote: "— Так.", blockIndex: 5, percent: 0 }, DIGEST).index, 4)
  assert.equal(resolveResumeTarget(blocks, { quote: "— Так.", blockIndex: 1, percent: 0 }, DIGEST).index, 2)
})

test("a repeated quote without an index picks the match nearest the stored percent", () => {
  assert.equal(resolveResumeTarget(blocks, { quote: "— Так.", percent: 70 }, DIGEST).index, 4)
})

test("missing quote with a matching digest falls back to the block index", () => {
  const target = resolveResumeTarget(blocks, { quote: "", blockIndex: 4, percent: 70, digest: DIGEST }, DIGEST)

  assert.deepEqual(target, { type: "block", index: 4, via: "index" })
})

test("digest mismatch ignores the block index and falls back to percent", () => {
  const target = resolveResumeTarget(blocks, { quote: "Цього тексту вже немає", blockIndex: 4, percent: 62.5, digest: "ffffffffffffffff" }, DIGEST)

  assert.deepEqual(target, { type: "percent", percent: 62.5, via: "percent" })
})

test("missing quote and missing digest fall back to percent", () => {
  assert.deepEqual(resolveResumeTarget(blocks, { percent: 40 }, DIGEST), { type: "percent", percent: 40, via: "percent" })
})

test("an index past the last block falls back to percent even when the digest matches", () => {
  const target = resolveResumeTarget(blocks, { blockIndex: 99, percent: 55, digest: DIGEST }, DIGEST)

  assert.equal(target.type, "percent")
})

test("percent is clamped and a locator without anything usable resolves to nothing", () => {
  assert.equal(resolveResumeTarget(blocks, { percent: 140 }, DIGEST).percent, 100)
  assert.equal(resolveResumeTarget(blocks, { quote: "Цього тексту вже немає" }, DIGEST), null)
  assert.equal(resolveResumeTarget(blocks, null, DIGEST), null)
})

test("normalizeText squishes whitespace the same way the server does", () => {
  assert.equal(normalizeText("  a \n\t b  "), "a b")
  assert.equal(normalizeText(undefined), "")
})
