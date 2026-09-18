import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    url: String,
    smallUrl: String,
    id: String,
    observe: { type: Boolean, default: false }
  }

  connect() {
    this.loaded = false
    this._onLazyLoad = () => this.load()
    this.element.addEventListener('lazy-bg:load', this._onLazyLoad)

    if (this.observeValue) this.observeNearViewport()
  }

  disconnect() {
    this.stopObserving()
    this.element.removeEventListener('lazy-bg:load', this._onLazyLoad)
    this.cancelPendingLoad()
  }

  load() {
    if (this.loaded) return

    const bgUrl = this.resolvedUrl();
    const bgDiv = this.element;

    if (!bgUrl || !bgDiv) {
      return;
    }

    this.loaded = true
    this.stopObserving()
    this.cancelPendingLoad()
    const img = new window.Image();
    this._pendingImage = img
    img.src = bgUrl;
    img.onload = () => {
      if (this._pendingImage !== img) return
      bgDiv.style.backgroundImage = `url(${JSON.stringify(bgUrl)})`;
      bgDiv.classList.add("transition-opacity", "duration-700", "opacity-100");
      bgDiv.dispatchEvent(new CustomEvent("lazy-bg:loaded", { bubbles: true }));
      this._pendingImage = null
    }
    img.onerror = () => {
      if (this._pendingImage !== img) return
      bgDiv.dispatchEvent(new CustomEvent("lazy-bg:error", { bubbles: true }));
      this._pendingImage = null
    }
  }

  resolvedUrl() {
    if (this.hasSmallUrlValue && this.smallUrlValue && this.preferSmallVariant()) {
      return this.smallUrlValue
    }
    return this.urlValue
  }

  preferSmallVariant() {
    return window.matchMedia("(max-width: 1023px)").matches
  }

  observeNearViewport() {
    if (!("IntersectionObserver" in window)) {
      this.load()
      return
    }

    this.observer = new IntersectionObserver((entries) => {
      if (!entries.some((entry) => entry.isIntersecting)) return
      this.stopObserving()
      this.load()
    }, { rootMargin: "200px 0px" })
    this.observer.observe(this.element)
  }

  stopObserving() {
    if (!this.observer) return
    this.observer.disconnect()
    this.observer = null
  }

  cancelPendingLoad() {
    if (!this._pendingImage) return

    this._pendingImage.onload = null
    this._pendingImage.onerror = null
    this._pendingImage.src = ''
    this._pendingImage = null
  }
}
