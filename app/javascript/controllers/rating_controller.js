import { Controller } from "@hotwired/stimulus"

// «Якість перекладу» card: the stars show the reader's own rating; the average and count come back from the server.
export default class extends Controller {
  static targets = ["star", "average", "summary"]
  static values = { url: String }
  static classes = ["on", "off"]

  connect() {
    this.rating = this.starTargets.filter((star) => star.querySelector("svg").classList.contains(this.onClasses[0])).length
  }

  async rate(event) {
    const previous = this.rating
    const rating = Number(event.currentTarget.dataset.starValue)
    this.paint(rating)

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ rating })
      })
      if (!response.ok) throw new Error(`rating failed: ${response.status}`)

      const data = await response.json()
      this.rating = rating
      this.averageTarget.textContent = data.rating_count > 0 ? Number(data.average_rating).toFixed(1) : "—"
      this.summaryTarget.textContent = data.summary
    } catch (error) {
      console.error(error)
      this.paint(previous)
    }
  }

  paint(rating) {
    this.starTargets.forEach((star) => {
      const icon = star.querySelector("svg")
      const on = Number(star.dataset.starValue) <= rating
      icon.classList.remove(...(on ? this.offClasses : this.onClasses))
      icon.classList.add(...(on ? this.onClasses : this.offClasses))
    })
  }
}
