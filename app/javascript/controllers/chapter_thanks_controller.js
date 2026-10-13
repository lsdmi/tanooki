import { Controller } from "@hotwired/stimulus"
import { fetchJson } from "translation_requests/http"
import { showErrorMessage } from "flash_toast"

// End-of-chapter thanks pill: optimistic toggle, server owns the plural label and the final count.
export default class extends Controller {
  static targets = ["button", "label", "count", "idleIcon", "thankedIcon", "status", "support"]
  static values = {
    url: String,
    thanked: Boolean,
    idleLabel: String,
    thankedLabel: String,
    status: String,
    error: String
  }
  static classes = ["idle", "thanked"]

  toggle() {
    if (this.buttonTarget.disabled) return

    const previous = this.thankedValue
    this.apply(!previous, this.optimisticCount(!previous))
    this.buttonTarget.disabled = true

    fetchJson(this.urlValue, { method: "POST" })
      .then(({ response, data }) => {
        if (!response.ok || data.error) {
          this.apply(previous, this.optimisticCount(previous))
          showErrorMessage(data.error || this.errorValue)
          return
        }

        this.apply(data.thanked, data.thanks_count)
      })
      .catch(() => {
        this.apply(previous, this.optimisticCount(previous))
        showErrorMessage(this.errorValue)
      })
      .finally(() => {
        this.buttonTarget.disabled = false
      })
  }

  apply(thanked, count) {
    this.thankedValue = thanked
    this.buttonTarget.className = (thanked ? this.thankedClasses : this.idleClasses).join(' ')
    this.buttonTarget.setAttribute("aria-pressed", thanked ? "true" : "false")
    this.labelTarget.textContent = thanked ? this.thankedLabelValue : this.idleLabelValue
    this.countTarget.textContent = String(count)
    this.buttonTarget.setAttribute(
      "aria-label",
      `${this.labelTarget.textContent}, ${this.countTarget.textContent}`
    )
    this.idleIconTarget.classList.toggle("hidden", thanked)
    this.thankedIconTarget.classList.toggle("hidden", !thanked)
    if (this.hasStatusTarget) this.statusTarget.classList.toggle("hidden", !thanked)
    if (this.hasSupportTarget) this.supportTarget.classList.toggle("hidden", !thanked)
  }

  optimisticCount(thanked) {
    const current = Number(this.countTarget.textContent) || 0
    return Math.max(0, current + (thanked ? 1 : -1))
  }
}
