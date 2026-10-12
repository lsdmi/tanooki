import { Controller } from "@hotwired/stimulus"

/**
 * A panel folded to its summary: `open` targets show only when unfolded, `closed` targets only when folded. The state
 * is kept per key in sessionStorage, so a panel that a Turbo Stream replaces comes back as the reader left it. The
 * change runs in a view transition (elements sharing a `view-transition-name` morph between the two states) unless
 * the reader prefers reduced motion. With nothing to unfold the header `button` hides and the panel counts as folded.
 */
export default class extends Controller {
  static targets = ["toggle", "button", "open", "closed"]
  static values = { key: String }

  connect() {
    this.apply(this.stored)
  }

  toggle() {
    const open = !this.isOpen
    sessionStorage.setItem(this.storageKey, open ? "1" : "0")

    if (!document.startViewTransition || matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.apply(open)
      return
    }

    document.startViewTransition(() => this.apply(open))
  }

  openTargetConnected(element) {
    element.hidden = !this.isOpen
    this.sync()
  }

  openTargetDisconnected() {
    this.sync()
  }

  closedTargetConnected(element) {
    element.hidden = this.isOpen
  }

  apply(open) {
    this.open = open
    this.openTargets.forEach((element) => { element.hidden = !open })
    this.closedTargets.forEach((element) => { element.hidden = open })
    this.sync()
  }

  sync() {
    const foldable = this.openTargets.length > 0
    const expanded = this.isOpen && foldable
    this.element.toggleAttribute("data-open", expanded)
    this.toggleTargets.forEach((toggle) => toggle.setAttribute("aria-expanded", String(expanded)))
    this.buttonTargets.forEach((button) => { button.hidden = !foldable })
  }

  get isOpen() {
    return this.open ?? this.stored
  }

  get stored() {
    return sessionStorage.getItem(this.storageKey) === "1"
  }

  get storageKey() {
    return `panel-fold:${this.keyValue}`
  }
}
