// Public open-report marks on reader blocks (+ optional message popover).
export const MARK_CLASS = "paragraph-report--marked"

export function markParagraphReportBlock(block) {
  if (!block) return
  block.classList.add(MARK_CLASS)
  block.removeAttribute("title")
  if (!block.hasAttribute("tabindex")) block.setAttribute("tabindex", "0")
}
