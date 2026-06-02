import { Controller } from "@hotwired/stimulus"

/** Gear menu on the chapter reader: font controls and staff edit link. */
export default class extends Controller {
  static targets = ["panel", "trigger"]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  toggle(event) {
    event.stopPropagation()
    if (this.panelTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.closeOnOutsideClick)
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
