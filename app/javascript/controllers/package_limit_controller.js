import { Controller } from "@hotwired/stimulus"

// One package at a time. Further boxes stay visible and locked.
export default class extends Controller {
  static targets = ["box"]
  static values = { max: 1 }

  connect() {
    this.toggle()
  }

  toggle() {
    const full = this.boxTargets.filter((box) => box.checked).length >= this.maxValue

    this.boxTargets.forEach((box) => {
      box.disabled = full && !box.checked
    })
  }
}
