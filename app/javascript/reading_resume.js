// Picks where to restore inside a chapter from a stored locator. No DOM access: blocks are plain
// { index, text } in document order, so the same code runs in the reader and under `node --test`.
//
// Order: a block whose text starts with the quote (nearest to the stored index when the quote
// repeats), then the stored block index but only while the content digest still matches, then
// the stored percent of #user-content.

export const normalizeText = (text) => String(text ?? "").replace(/\s+/g, " ").trim()

export function resolveResumeTarget(blocks, locator, digest) {
  if (!locator) return null

  const quoted = quoteMatch(blocks, locator)
  if (quoted) return { type: "block", index: quoted.index, via: "quote" }

  if (locator.digest && locator.digest === digest && blocks.some((block) => block.index === locator.blockIndex)) {
    return { type: "block", index: locator.blockIndex, via: "index" }
  }

  if (Number.isFinite(locator.percent)) {
    return { type: "percent", percent: Math.min(100, Math.max(0, locator.percent)), via: "percent" }
  }

  return null
}

function quoteMatch(blocks, locator) {
  const quote = normalizeText(locator.quote)
  if (!quote) return null

  const matches = blocks.filter((block) => normalizeText(block.text).startsWith(quote))
  if (matches.length <= 1) return matches[0] ?? null

  const distance = Number.isInteger(locator.blockIndex)
    ? (block) => Math.abs(block.index - locator.blockIndex)
    : (block) => Math.abs((blocks.indexOf(block) / blocks.length) * 100 - (locator.percent ?? 0))
  return matches.reduce((best, block) => (distance(block) < distance(best) ? block : best))
}
