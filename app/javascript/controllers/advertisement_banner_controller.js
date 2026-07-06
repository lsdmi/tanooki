import { Controller } from "@hotwired/stimulus"

// Native house video banners: replace the <video> after Turbo morph so autoplay can restart.
export default class extends Controller {
  static targets = ["placeholder"]
  static values = { key: String }

  connect() {
    this.playGeneration = 0
    this.previousKey = undefined
    this.boundVisit = this.onVisit.bind(this)
    document.addEventListener("baka:banner-visit", this.boundVisit)
    this.play()
  }

  disconnect() {
    document.removeEventListener("baka:banner-visit", this.boundVisit)
  }

  keyValueChanged() {
    if (this.previousKey === undefined) {
      this.previousKey = this.keyValue
      return
    }

    if (this.previousKey === this.keyValue) return

    this.previousKey = this.keyValue
    this.refreshVideo()
  }

  onVisit() {
    this.refreshVideo()
  }

  refreshVideo() {
    this.playGeneration += 1
    this.replaceVideoElement()
    this.play()
  }

  replaceVideoElement() {
    const video = this.element.querySelector("video")
    if (!video) return null

    const fresh = document.createElement("video")
    fresh.className = video.className
    fresh.autoplay = true
    fresh.loop = true
    fresh.muted = true
    fresh.playsInline = true
    fresh.preload = "none"
    if (video.poster) fresh.poster = video.poster

    const source = video.querySelector("source")
    if (source?.src) {
      const sourceEl = document.createElement("source")
      sourceEl.src = source.src
      if (source.type) sourceEl.type = source.type
      fresh.appendChild(sourceEl)
    } else if (video.currentSrc || video.src) {
      fresh.src = video.currentSrc || video.src
    }

    video.replaceWith(fresh)
    return fresh
  }

  play() {
    const generation = this.playGeneration
    const video = this.element.querySelector("video")
    if (!video) return

    const showPlaceholder = () => {
      if (generation !== this.playGeneration) return
      if (this.hasPlaceholderTarget) this.placeholderTarget.classList.remove("hidden")
    }
    const hidePlaceholder = () => {
      if (generation !== this.playGeneration) return
      if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden")
    }

    video.addEventListener("playing", hidePlaceholder, { once: true })
    video.addEventListener("error", showPlaceholder, { once: true })

    if (video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA) hidePlaceholder()

    video.load()
    video.play().catch(showPlaceholder)
  }
}
