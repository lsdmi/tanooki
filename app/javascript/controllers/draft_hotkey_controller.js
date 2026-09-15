import { Controller } from "@hotwired/stimulus"

// Ctrl/⌘+S submits the draft button when it is present on the composer.
export default class extends Controller {
  static targets = ["draftSubmit"]

  connect() {
    this.onKeydown = this.onKeydown.bind(this)
    window.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    window.removeEventListener("keydown", this.onKeydown)
  }

  onKeydown(event) {
    if (!this.isSaveChord(event)) return
    if (!this.hasDraftSubmitTarget) return

    event.preventDefault()
    this.draftSubmitTarget.click()
  }

  isSaveChord(event) {
    if (!(event.metaKey || event.ctrlKey) || event.shiftKey || event.altKey) return false

    return event.key === "s" || event.key === "S"
  }
}
