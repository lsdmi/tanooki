import { Controller } from "@hotwired/stimulus"

// A reader may turn off two packages. Further boxes stay visible and locked.
export default class extends Controller {
  static targets = ["box"]

  connect() {
    this.toggle()
  }

  toggle() {
    const full = this.boxTargets.filter((box) => box.checked).length >= 2

    this.boxTargets.forEach((box) => {
      box.disabled = full && !box.checked
    })
  }
}
