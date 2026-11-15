// Open-report marks on reader quotes (fallback: whole block).
const MARK_CLASS = "paragraph-report--marked"

export function normalizeMarkText(text) {
  return String(text ?? "").replace(/\s+/g, " ").trim()
}

function markParagraphReportBlock(block) {
  if (!block) return null
  block.classList.add(MARK_CLASS)
  ensureInteractive(block)
  return block
}

// Wrap the first normalized match of `quote` inside the block. Falls back to the whole block.
export function markParagraphReportQuote(block, quote) {
  if (!block) return null

  const needle = normalizeMarkText(quote)
  if (!needle) return markParagraphReportBlock(block)

  const existing = findMarkForQuote(block, needle)
  if (existing) {
    ensureInteractive(existing)
    return existing
  }

  const range = findNormalizedRange(block, needle)
  if (!range) return markParagraphReportBlock(block)

  const mark = document.createElement("mark")
  mark.className = MARK_CLASS
  mark.dataset.rpQ = needle
  ensureInteractive(mark)

  try {
    const contents = range.extractContents()
    mark.appendChild(contents)
    range.insertNode(mark)
  } catch {
    return markParagraphReportBlock(block)
  }

  return mark
}

function findMarkForQuote(block, needle) {
  return [...block.querySelectorAll(`mark.${MARK_CLASS}[data-rp-q]`)].find(
    (el) => normalizeMarkText(el.dataset.rpQ) === needle
  ) || null
}

function ensureInteractive(el) {
  el.removeAttribute("title")
  if (!el.hasAttribute("tabindex")) el.setAttribute("tabindex", "0")
}

// Map collapsed whitespace (same as report quotes) back onto text-node offsets.
function findNormalizedRange(root, needle) {
  const { normalized, map } = buildNormalizedMap(root)
  if (!needle || !normalized) return null

  const start = normalized.indexOf(needle)
  if (start < 0) return null

  const startPoint = map[start]
  const endPoint = map[start + needle.length - 1]
  if (!startPoint || !endPoint) return null

  const range = document.createRange()
  range.setStart(startPoint.node, startPoint.offset)
  range.setEnd(endPoint.node, endPoint.offset + 1)
  return range
}

function buildNormalizedMap(root) {
  const map = []
  let normalized = ""
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)

  let node
  while ((node = walker.nextNode())) {
    const text = node.nodeValue || ""
    for (let i = 0; i < text.length; i += 1) {
      const ch = text[i]
      if (/\s/.test(ch)) {
        if (!normalized.length || normalized.endsWith(" ")) continue
        normalized += " "
        map.push({ node, offset: i })
      } else {
        normalized += ch
        map.push({ node, offset: i })
      }
    }
  }

  while (normalized.endsWith(" ")) {
    normalized = normalized.slice(0, -1)
    map.pop()
  }

  return { normalized, map }
}
