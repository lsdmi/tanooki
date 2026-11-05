import { Controller } from "@hotwired/stimulus"

// Soften the fixed mobile CTA when the user scrolls near the page footer.
export default class extends Controller {
  connect() {
    this.onScroll = () => {
      const nearBottom = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 80
      this.element.classList.toggle("opacity-[0.55]", nearBottom)
      this.element.classList.toggle("pointer-events-none", nearBottom)
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }
}
