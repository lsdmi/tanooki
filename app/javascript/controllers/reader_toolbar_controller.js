import { Controller } from "@hotwired/stimulus"

/** Hides the sticky reader toolbar while scrolling down; shows it instantly on scroll up. */
export default class extends Controller {
  static classes = ["hidden"]

  connect() {
    this.lastScrollY = window.scrollY
    this.isHidden = false
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    this.show()
  }

  onScroll() {
    const scrollY = window.scrollY

    if (scrollY <= 0) {
      this.show()
      this.lastScrollY = scrollY
      return
    }

    const delta = scrollY - this.lastScrollY
    if (Math.abs(delta) < 4) return

    if (delta > 0) this.hide()
    else this.show()

    this.lastScrollY = scrollY
  }

  hide() {
    if (this.isHidden) return

    this.isHidden = true
    this.element.classList.remove("transition-none")
    this.element.classList.add(this.hiddenClass)
  }

  show() {
    if (!this.isHidden) return

    this.isHidden = false
    if (this.reducedMotion) {
      this.element.classList.remove(this.hiddenClass)
      return
    }

    this.element.classList.add("transition-none")
    this.element.classList.remove(this.hiddenClass)
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.element.classList.remove("transition-none")
      })
    })
  }
}
