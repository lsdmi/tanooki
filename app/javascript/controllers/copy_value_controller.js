import { Controller } from "@hotwired/stimulus"

/** Copies the source input. Falls back to selecting it when the clipboard is unavailable. */
export default class extends Controller {
  static targets = ["source", "button"]
  static values = { copied: String }

  copy() {
    const value = this.sourceTarget.value
    if (!navigator.clipboard) {
      this.sourceTarget.select()
      return
    }

    navigator.clipboard.writeText(value).then(() => this.flash()).catch(() => this.sourceTarget.select())
  }

  flash() {
    const button = this.buttonTarget
    const previous = button.textContent
    button.textContent = this.copiedValue
    setTimeout(() => { button.textContent = previous }, 1500)
  }
}
