import { Controller } from "@hotwired/stimulus"

// Live character count under a textarea.
export default class extends Controller {
  static targets = ["input", "count"]
  static values = { max: { type: Number, default: 1000 }, min: { type: Number, default: 25 } }

  connect() {
    this.update()
  }

  update() {
    if (!this.hasInputTarget || !this.hasCountTarget) return
    const length = this.inputTarget.value.length
    this.countTarget.textContent = `${length} / ${this.maxValue}`
    this.countTarget.classList.toggle("text-status-danger-solid", length > 0 && length < this.minValue)
  }
}
