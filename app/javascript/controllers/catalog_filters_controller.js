import { Controller } from "@hotwired/stimulus"

/** Side drawer for Storage catalog filters (genres + quick flags). */
export default class extends Controller {
  static targets = ["backdrop", "panel", "trigger", "form"]

  connect() {
    this._onEscape = this._onEscape.bind(this)
    this._onTurboLoad = () => this.close()
    this._onFrameLoad = (event) => {
      if (event.target?.id === "fiction-list-page") this.close()
    }
    document.addEventListener("turbo:load", this._onTurboLoad)
    document.addEventListener("turbo:frame-load", this._onFrameLoad)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this._onTurboLoad)
    document.removeEventListener("turbo:frame-load", this._onFrameLoad)
    document.removeEventListener("keydown", this._onEscape)
    this.close()
  }

  open(event) {
    event?.preventDefault()
    event?.stopPropagation()
    if (!this.hasBackdropTarget || !this.hasPanelTarget) return

    this.restoreEmptyGenre()

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

    if (wasOpen && this.focusWasInDrawer()) this.opener?.focus({ preventScroll: true })
    this.opener = null
  }

  clear(event) {
    event?.preventDefault()
    if (!this.hasFormTarget) return

    this.formTarget.querySelectorAll('input[type="checkbox"]').forEach((input) => {
      input.checked = false
    })
    this.formTarget.querySelectorAll('input[type="radio"][name="genre"]').forEach((input) => {
      input.disabled = false
      input.checked = input.value === ""
    })
    this.omitEmptyGenre()
    this.formTarget.requestSubmit()
  }

  prepareSubmit() {
    this.omitEmptyGenre()
  }

  applied(event) {
    this.restoreEmptyGenre()
    if (event.detail?.success === false) return
    this.close()
  }

  // Skip genre= in the query when «Усі» is selected, then re-enable so it stays clickable.
  omitEmptyGenre() {
    if (!this.hasFormTarget) return

    const empty = this.formTarget.querySelector('input[type="radio"][name="genre"][value=""]')
    if (empty?.checked) empty.disabled = true
  }

  restoreEmptyGenre() {
    if (!this.hasFormTarget) return

    const empty = this.formTarget.querySelector('input[type="radio"][name="genre"][value=""]')
    if (!empty) return

    empty.disabled = false
    if (![...this.formTarget.querySelectorAll('input[type="radio"][name="genre"]')].some((input) => input.checked)) {
      empty.checked = true
    }
  }

  setExpanded(open) {
    this.triggerTargets.forEach((trigger) => {
      trigger.setAttribute("aria-expanded", open ? "true" : "false")
    })
  }

  focusWasInDrawer() {
    const active = document.activeElement
    return active instanceof HTMLElement && this.panelTarget.contains(active)
  }

  _onEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
