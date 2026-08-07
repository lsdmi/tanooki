import { Controller } from "@hotwired/stimulus"

// Prevent scroll wheel from changing <input type="number"> while focused.
export default class extends Controller {
  connect() {
    this.onWheel = this.onWheel.bind(this)
    this.element.addEventListener("wheel", this.onWheel, { passive: false })
  }

  disconnect() {
    this.element.removeEventListener("wheel", this.onWheel)
  }

  onWheel(event) {
    if (document.activeElement === this.element) event.preventDefault()
  }
}
