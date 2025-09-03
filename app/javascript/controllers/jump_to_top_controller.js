import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.button = document.getElementById('jump-to-top')
    this.handleScroll = this.handleScroll.bind(this)
    this.jumpToTop = this.jumpToTop.bind(this)
    
    // Listen for scroll events
    window.addEventListener('scroll', this.handleScroll)
    
    // Add click event to button
    if (this.button) {
      this.button.addEventListener('click', this.jumpToTop)
    }
  }

  disconnect() {
    window.removeEventListener('scroll', this.handleScroll)
    if (this.button) {
      this.button.removeEventListener('click', this.jumpToTop)
    }
  }

  handleScroll() {
    // Show button when scrolled down more than 300px
    if (window.scrollY > 300) {
      this.button.style.display = 'block'
    } else {
      this.button.style.display = 'none'
    }
  }

  jumpToTop() {
    // Smooth scroll to top
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    })
  }
}
