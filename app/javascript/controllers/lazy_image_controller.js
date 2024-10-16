import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]
  static values = { url: String }

  connect() {
    if ('IntersectionObserver' in window) {
      this.observer = new IntersectionObserver(this.onIntersection.bind(this))
      this.observer.observe(this.imageTarget)
    } else {
      this.loadImage()
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  onIntersection(entries) {
    if (entries[0].isIntersecting) {
      this.observer.disconnect()
      this.loadImage()
    }
  }

  loadImage() {
    this.imageTarget.src = this.urlValue
    this.imageTarget.classList.remove("opacity-0")
  }
}