import { Controller } from "@hotwired/stimulus"

// Native house video banners: autoplay does not restart after Turbo morph/navigation.
export default class extends Controller {
  static targets = ["placeholder"]

  connect() {
    this._onPageChange = this.play.bind(this)
    document.addEventListener("turbo:load", this._onPageChange)
    document.addEventListener("turbo:morph", this._onPageChange)
    this.play()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this._onPageChange)
    document.removeEventListener("turbo:morph", this._onPageChange)
  }

  play() {
    const video = this.element.querySelector("video")
    if (!video) return

    const showPlaceholder = () => {
      if (this.hasPlaceholderTarget) this.placeholderTarget.classList.remove("hidden")
    }
    const hidePlaceholder = () => {
      if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden")
    }

    video.addEventListener("playing", hidePlaceholder, { once: true })
    video.addEventListener("error", showPlaceholder, { once: true })

    if (video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA) hidePlaceholder()

    video.load()
    video.play().catch(showPlaceholder)
  }
}
