import { Controller } from "@hotwired/stimulus"
import { acknowledgeAdultContent } from "adult_content_disclaimer"

/** Dismissible 18+ disclaimer; acknowledgement is stored in the Rails session. */
export default class extends Controller {
  disconnect() {
    this.abortAcknowledge()
    this.hide()
  }

  dismiss() {
    this.unlockGatedContent()
    this.hide()
    this.abortAcknowledge()
    this.acknowledgeAbortController = new AbortController()
    acknowledgeAdultContent({ signal: this.acknowledgeAbortController.signal }).catch(() => {})
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
