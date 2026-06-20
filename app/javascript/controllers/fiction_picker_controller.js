import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["frame", "image"]

  connect() {
    if (this.imageTargets.length > 0) {
      this.highlightImage(this.imageTargets[0])
    }
  }

  disconnect() {
    this.abortDetailsFetch()
  }

  selectFiction(event) {
    const fictionId = event.currentTarget.dataset.fictionPickerIdParam

    this.imageTargets.forEach((img) => {
      img.classList.remove("ring-2", "ring-cyan-700", "dark:ring-rose-800")
    })

    this.highlightImage(event.currentTarget)

    if (!document.startViewTransition) {
      this.updateFrame(fictionId)
      return
    }

    document.startViewTransition(() => {
      this.updateFrame(fictionId)
    })
  }

  updateFrame(fictionId) {
    const frame = document.getElementById("fiction_details")
    if (!frame) return

    frame.setAttribute("data-transitioning", "true")
    this.abortDetailsFetch()
    this.detailsAbortController = new AbortController()

    fetch(`/fictions/${fictionId}/details`, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
      },
      signal: this.detailsAbortController.signal,
    })
      .then((response) => response.text())
      .then((html) => {
        Turbo.renderStreamMessage(html)
      })
      .catch((error) => {
        if (error.name === "AbortError") return
        throw error
      })
      .finally(() => {
        frame.removeAttribute("data-transitioning")
        this.detailsAbortController = null
      })
  }

  abortDetailsFetch() {
    if (!this.detailsAbortController) return

    this.detailsAbortController.abort()
    this.detailsAbortController = null
  }

  highlightImage(image) {
    image.classList.add("ring-2", "ring-cyan-700", "dark:ring-rose-800")
  }
}
