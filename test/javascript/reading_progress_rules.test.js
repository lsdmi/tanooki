import { test } from "node:test"
import assert from "node:assert/strict"
import { fitsScreen, isCompleted, isEngaged, seenFraction } from "../../app/javascript/reading_progress_rules.js"

const VIEWPORT = 800
const LONG = { height: 8000 }

test("seen is the share of the text that has entered the viewport", () => {
  assert.equal(seenFraction(0, { top: 0, height: 8000 }, VIEWPORT), 0.1)
  assert.equal(seenFraction(0, { top: -6400, height: 8000 }, VIEWPORT), 0.9)
})

test("seen never goes back when the reader scrolls up, and stays within 0–1", () => {
  assert.equal(seenFraction(0.6, { top: 0, height: 8000 }, VIEWPORT), 0.6)
  assert.equal(seenFraction(0, { top: 900, height: 8000 }, VIEWPORT), 0)
  assert.equal(seenFraction(0, { top: -9000, height: 8000 }, VIEWPORT), 1)
})

test("a page with no text height keeps what was seen", () => {
  assert.equal(seenFraction(0.4, { top: 0, height: 0 }, VIEWPORT), 0.4)
})

test("a chapter fits when it is no taller than the viewport", () => {
  assert.equal(fitsScreen({ height: 800 }, VIEWPORT), true)
  assert.equal(fitsScreen({ height: 801 }, VIEWPORT), false)
})

test("nothing counts as reading in the first 4 seconds, however far the reader scrolls", () => {
  assert.equal(isEngaged({ dwellMs: 3999, seen: 1, fits: false }), false)
})

test("a long chapter is engaged by scrolling a quarter, or by 8 seconds and 15%", () => {
  assert.equal(isEngaged({ dwellMs: 4000, seen: 0.25, fits: false }), true)
  assert.equal(isEngaged({ dwellMs: 8000, seen: 0.15, fits: false }), true)
  assert.equal(isEngaged({ dwellMs: 7999, seen: 0.24, fits: false }), false)
})

test("a one-screen chapter is engaged only after 8 seconds", () => {
  assert.equal(isEngaged({ dwellMs: 7999, seen: 1, fits: true }), false)
  assert.equal(isEngaged({ dwellMs: 8000, seen: 1, fits: true }), true)
})

test("scrolling completes a long chapter at 90%", () => {
  assert.equal(isCompleted({ seen: 0.89, fits: fitsScreen(LONG, VIEWPORT) }, "scroll"), false)
  assert.equal(isCompleted({ seen: 0.9, fits: fitsScreen(LONG, VIEWPORT) }, "scroll"), true)
})

test("«Наступний розділ» completes a long chapter from 70%", () => {
  assert.equal(isCompleted({ seen: 0.69, fits: false }, "next"), false)
  assert.equal(isCompleted({ seen: 0.7, fits: false }, "next"), true)
})

test("a one-screen chapter completes as soon as it is engaged", () => {
  assert.equal(isCompleted({ seen: 1, fits: true }, "scroll"), true)
  assert.equal(isCompleted({ seen: 1, fits: true }, "next"), true)
})
