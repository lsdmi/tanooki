import { Controller } from "@hotwired/stimulus"

// Swaps the audience helper sentence when the editor picks another band.
export default class extends Controller {
  static targets = ["hint"]
  static values = { hints: Object }

  connect() {
    this.show()
  }

  show() {
    const selected = this.element.querySelector("input[type='radio']:checked")
    if (!selected || !this.hasHintTarget) return

    const hint = this.hintsValue[selected.value]
    if (hint) this.hintTarget.textContent = hint
  }
}
