import { Controller } from "@hotwired/stimulus"

/** Brief spin feedback on fiction chapter order toggle (turbo_stream reorder). */
export default class extends Controller {
  spin() {
    this.element.classList.add("animate-spin")
    this._spinTimeout = window.setTimeout(() => {
      this.element.classList.remove("animate-spin")
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
