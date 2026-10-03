import { Controller } from "@hotwired/stimulus"

/** Brief spin feedback on fiction chapter order toggle (turbo_stream reorder). Spins the icon target when there is one. */
export default class extends Controller {
  static targets = ["icon"]

  spin() {
    const element = this.hasIconTarget ? this.iconTarget : this.element
    element.classList.add("animate-spin")
    this._spinTimeout = window.setTimeout(() => {
      element.classList.remove("animate-spin")
      this._spinTimeout = null
    }, 500)
  }

  disconnect() {
    if (this._spinTimeout) {
      window.clearTimeout(this._spinTimeout)
      this._spinTimeout = null
    }
  }
}
