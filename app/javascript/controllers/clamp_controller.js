import { Controller } from "@hotwired/stimulus"

// Clamped text with «Розгорнути» / «Згорнути». The toggle shows only when the clamp actually cuts the text.
// Measured on resize too: inside a hidden tab panel the text has no size until the tab opens.
export default class extends Controller {
  static targets = ["content", "toggle", "label", "icon"]
  static classes = ["clamped"]
  static values = { expandLabel: String, collapseLabel: String }

  connect() {
    this.expanded = false
    this.observer = new ResizeObserver(() => this.measure())
    this.observer.observe(this.contentTarget)
    this.measure()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  measure() {
    if (this.expanded) return

    const { scrollHeight, clientHeight } = this.contentTarget
    this.toggleTarget.hidden = clientHeight === 0 || scrollHeight <= clientHeight + 1
  }

  toggle() {
    this.expanded = !this.expanded
    this.clampedClasses.forEach((name) => this.contentTarget.classList.toggle(name, !this.expanded))
    this.toggleTarget.setAttribute("aria-expanded", String(this.expanded))
    this.labelTarget.textContent = this.expanded ? this.collapseLabelValue : this.expandLabelValue
    this.iconTarget.classList.toggle("rotate-180", this.expanded)
  }
}
