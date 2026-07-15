import { Controller } from "@hotwired/stimulus"

// Home «Новини та Блоги» cards: title max 2 lines; description 2 lines, or 3 when title is 1 line.
export default class extends Controller {
  static targets = ["title", "description"]

  connect() {
    this.applyDescriptionClamp()
    this.resizeObserver = new ResizeObserver(() => this.applyDescriptionClamp())
    this.resizeObserver.observe(this.titleTarget)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
  }

  applyDescriptionClamp() {
    const description = this.descriptionTarget
    description.classList.remove("line-clamp-2", "line-clamp-3")
    description.classList.add(this.titleLineCount() === 1 ? "line-clamp-3" : "line-clamp-2")
  }

  titleLineCount() {
    const title = this.titleTarget.querySelector("a") || this.titleTarget
    const rects = title.getClientRects()

    return Math.min(2, Math.max(1, rects.length))
  }
}
