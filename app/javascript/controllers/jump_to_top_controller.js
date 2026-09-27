import { Controller } from "@hotwired/stimulus"

const REVEAL_AFTER_PX = 300

/** Jump-to-top button, plus any `reveal` targets (the phone Зміст button) shown once past the hero. */
export default class extends Controller {
  static targets = ["reveal"]

  connect() {
    this.button = document.getElementById('jump-to-top')
    this.handleScroll = this.handleScroll.bind(this)
    this.jumpToTop = this.jumpToTop.bind(this)

    window.addEventListener('scroll', this.handleScroll, { passive: true })
    if (this.button) this.button.addEventListener('click', this.jumpToTop)
    this.handleScroll()
  }

  disconnect() {
    window.removeEventListener('scroll', this.handleScroll)
    if (this.button) {
      this.button.removeEventListener('click', this.jumpToTop)
    }
  }

  handleScroll() {
    const past = window.scrollY > REVEAL_AFTER_PX
    if (this.button) this.button.style.display = past ? 'block' : 'none'
    this.revealTargets.forEach((element) => { element.hidden = !past })
  }

  jumpToTop() {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    })
  }
}
