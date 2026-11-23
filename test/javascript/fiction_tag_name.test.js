import { test } from "node:test"
import assert from "node:assert/strict"
import { findSameTag, normalizeTagName, tagKey, tagNameProblem } from "../../app/javascript/fiction_tag_name.js"

const LIMITS = { selectedCount: 0, max: 10, maxLength: 40 }

test("a typed name is squished, loses leading hashes and unifies apostrophes and ё", () => {
  assert.equal(normalizeTagName("  #пригода \n у   часі "), "пригода у часі")
  assert.equal(normalizeTagName("пам'ять"), "пам’ять")
  assert.equal(normalizeTagName("памʼять"), "пам’ять")
  assert.equal(normalizeTagName("Ёж"), "Еж")
})

test("case is kept for display", () => {
  assert.equal(normalizeTagName("ЛітРПГ"), "ЛітРПГ")
})

test("nothing typed normalizes to an empty string", () => {
  assert.equal(normalizeTagName(null), "")
  assert.equal(normalizeTagName("  # "), "")
})

test("the same tag is found whatever the case or apostrophe style", () => {
  const options = ["Переродження", "Пам’ять"]

  assert.equal(findSameTag(options, "ПЕРЕРОДЖЕННЯ"), "Переродження")
  assert.equal(findSameTag(options, "пам'ять"), "Пам’ять")
  assert.equal(findSameTag(options, "Магія"), undefined)
})

test("tagKey ignores case", () => {
  assert.equal(tagKey("ЮРІ"), tagKey("юрі"))
})

test("a name is refused when empty, too long, or the work already has the maximum", () => {
  assert.equal(tagNameProblem("", LIMITS), "empty")
  assert.equal(tagNameProblem("а".repeat(41), LIMITS), "too_long")
  assert.equal(tagNameProblem("а".repeat(40), LIMITS), null)
  assert.equal(tagNameProblem("Магія", { ...LIMITS, selectedCount: 10 }), "too_many")
  assert.equal(tagNameProblem("Магія", { ...LIMITS, selectedCount: 9 }), null)
})
