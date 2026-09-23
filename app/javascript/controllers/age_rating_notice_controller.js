import { Controller } from "@hotwired/stimulus"
import { acknowledgeAdultContent } from "adult_content_disclaimer"

/** 16+ hides for this page load; 18+ unlocks the reader gate and persists acknowledgement. */
export default class extends Controller {
  static values = { rating: String }

  disconnect() {
    this.abortAcknowledge()
    this.hide()
  }

  dismiss() {
    if (this.eighteen) this.unlockGatedContent()
    this.hide()
    if (!this.eighteen) return

    this.abortAcknowledge()
    this.acknowledgeAbortController = new AbortController()
    acknowledgeAdultContent({ signal: this.acknowledgeAbortController.signal }).catch(() => {})
  }

  get eighteen() {
    return this.ratingValue === "eighteen"
  }

  unlockGatedContent() {
    document.querySelectorAll("[data-adult-content-gate-content]").forEach((element) => {
      element.classList.remove("adult-content-gate--locked")
    })
  }

  hide() {
    this.element.classList.add("hidden")
    this.element.setAttribute("hidden", "")
  }

  abortAcknowledge() {
    if (!this.acknowledgeAbortController) return

    this.acknowledgeAbortController.abort()
    this.acknowledgeAbortController = null
  }
}
