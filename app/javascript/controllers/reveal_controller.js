import { Controller } from "@hotwired/stimulus"

/** Shows the hidden items and drops the trigger («Показати ще N відповіді»). */
export default class extends Controller {
  static targets = ["item", "trigger"]

  show() {
    this.itemTargets.forEach((item) => item.removeAttribute("hidden"))
    if (this.hasTriggerTarget) this.triggerTarget.remove()
  }
}
