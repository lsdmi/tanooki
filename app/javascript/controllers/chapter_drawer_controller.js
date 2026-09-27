import { Controller } from "@hotwired/stimulus"

/** Slide-out chapter list on the immersive chapter reader. */
export default class extends Controller {
  static targets = ["backdrop", "panel", "trigger"]

  connect() {
    this._onEscape = this._onEscape.bind(this)
    this._onTurboLoad = () => this.close()
    document.addEventListener("turbo:load", this._onTurboLoad)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this._onTurboLoad)
    document.removeEventListener("keydown", this._onEscape)
    this.close()
  }

  open(event) {
    event?.preventDefault()
    event?.stopPropagation()
    if (!this.hasBackdropTarget || !this.hasPanelTarget) return

    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.add("opacity-100", "pointer-events-auto")
    this.backdropTarget.setAttribute("aria-hidden", "false")

    this.panelTarget.classList.remove("translate-x-full")
    this.panelTarget.classList.add("translate-x-0")

    this.setExpanded(true)
    this.opener = event?.currentTarget instanceof HTMLElement ? event.currentTarget : null
    this.panelTarget.focus({ preventScroll: true })

    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this._onEscape)

    const accordionRoot = this.panelTarget.querySelector('[data-controller*="chapters-accordion"]')
    if (accordionRoot) {
      const accordion = this.application.getControllerForElementAndIdentifier(accordionRoot, "chapters-accordion")
      window.requestAnimationFrame(() => accordion?.initializeSections())
    }
  }

  close() {
    if (!this.hasBackdropTarget || !this.hasPanelTarget) return

    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.remove("opacity-100", "pointer-events-auto")
    this.backdropTarget.setAttribute("aria-hidden", "true")

    const wasOpen = this.panelTarget.classList.contains("translate-x-0")
    this.panelTarget.classList.add("translate-x-full")
    this.panelTarget.classList.remove("translate-x-0")

    this.setExpanded(false)

    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this._onEscape)

    this.resetChapterDrawerSearch()
    if (wasOpen && this.focusWasInDrawer()) this.opener?.focus({ preventScroll: true })
    this.opener = null
  }

  focusWasInDrawer() {
    const active = document.activeElement
    return !active || active === document.body || this.panelTarget.contains(active)
  }

  setExpanded(expanded) {
    this.triggerTargets.forEach((trigger) => trigger.setAttribute("aria-expanded", String(expanded)))
  }

  resetChapterDrawerSearch() {
    const panel = this.hasPanelTarget ? this.panelTarget : null
    const search = panel?.querySelector("[data-controller~='chapter-drawer-search']")
    if (!search) return

    const controller = this.application.getControllerForElementAndIdentifier(search, "chapter-drawer-search")
    controller?.clear()
  }

  _onEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
