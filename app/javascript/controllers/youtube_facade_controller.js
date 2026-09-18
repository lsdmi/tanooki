import { Controller } from "@hotwired/stimulus"

const LETTERBOX_ZOOM = "scale(1.34)"

// Homepage / catalog featured player: poster until click, then a real YouTube iframe.
export default class extends Controller {
  static targets = ["facade", "poster"]
  static values = { videoId: String, title: String, fallbackPoster: String }

  connect() {
    if (!this.hasPosterTarget) return

    this.onPosterLoad = () => this.ensurePosterQuality()
    this.onPosterError = () => this.useFallbackPoster()
    this.posterTarget.addEventListener("load", this.onPosterLoad)
    this.posterTarget.addEventListener("error", this.onPosterError)
    if (this.posterTarget.complete) this.ensurePosterQuality()
  }

  disconnect() {
    if (!this.hasPosterTarget) return

    this.posterTarget.removeEventListener("load", this.onPosterLoad)
    this.posterTarget.removeEventListener("error", this.onPosterError)
  }

  play(event) {
    event.preventDefault()
    if (this.playing || !this.hasFacadeTarget || !this.videoIdValue) return

    const iframe = document.createElement("iframe")
    iframe.src = this.embedSrc()
    iframe.title = this.titleValue
    iframe.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    iframe.allowFullscreen = true
    iframe.referrerPolicy = "strict-origin-when-cross-origin"
    iframe.className = "absolute inset-0 h-full w-full rounded-xl"

    this.facadeTarget.replaceWith(iframe)
    this.playing = true
    iframe.focus()
  }

  ensurePosterQuality() {
    if (!this.hasPosterTarget || this.usedFallback) return
    if (!this.posterTarget.complete) return
    // Missing maxres is often a 120×90 placeholder rather than a network error.
    if (this.posterTarget.naturalWidth > 120) return

    this.useFallbackPoster()
  }

  useFallbackPoster() {
    if (this.usedFallback || !this.hasPosterTarget || !this.fallbackPosterValue) return

    this.usedFallback = true
    const img = this.posterTarget
    img.width = 640
    img.height = 480
    img.style.transform = LETTERBOX_ZOOM
    img.src = this.fallbackPosterValue
  }

  embedSrc() {
    return `https://www.youtube.com/embed/${encodeURIComponent(this.videoIdValue)}?autoplay=1`
  }
}
