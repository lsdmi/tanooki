import { Controller } from "@hotwired/stimulus"

// Marks sticky section nav when it sticks under the top edge.
export default class extends Controller {
  connect() {
    this.observer = new IntersectionObserver(
      ([entry]) => {
        this.element.classList.toggle("shadow-popover", entry.intersectionRatio < 1)
      },
      { threshold: [1], rootMargin: "-1px 0px 0px 0px" }
    )
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
