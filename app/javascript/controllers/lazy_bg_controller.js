import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const bgId = this.element.dataset.lazyBgId
    const bgUrl = this.element.dataset.lazyBgUrl
    const spinner = document.getElementById(`spinner-${bgId}`)
    const bgDiv = this.element

    if (!bgUrl || !spinner || !bgDiv) return

    // Use IntersectionObserver for lazy loading
    if ('IntersectionObserver' in window) {
      const observer = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting) {
          observer.disconnect()
          this.loadImage(bgUrl, bgDiv, spinner)
        }
      })
      observer.observe(bgDiv)
    } else {
      this.loadImage(bgUrl, bgDiv, spinner)
    }
  }

  loadImage(url, bgDiv, spinner) {
    const img = new window.Image()
    img.src = url
    img.onload = () => {
      bgDiv.style.backgroundImage = `url('${url}')`
      spinner.classList.add("hidden")
      bgDiv.classList.add("transition-opacity", "duration-700", "opacity-100")
    }
    img.onerror = () => {
      spinner.classList.add("hidden")
      // Optionally: set a fallback background or error state
    }
  }
}
