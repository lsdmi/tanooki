import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { url: String, id: String }

  connect() {
    this._onLazyLoad = () => this.load()
    this.element.addEventListener('lazy-bg:load', this._onLazyLoad)
  }

  disconnect() {
    this.element.removeEventListener('lazy-bg:load', this._onLazyLoad)
    this.cancelPendingLoad()
  }

  load() {
    const bgUrl = this.urlValue;
    const bgDiv = this.element;

    if (!bgUrl || !bgDiv) {
      return;
    }

    this.cancelPendingLoad()
    const img = new window.Image();
    this._pendingImage = img
    img.src = bgUrl;
    img.onload = () => {
      if (this._pendingImage !== img) return
      bgDiv.style.backgroundImage = `url('${bgUrl}')`;
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

  cancelPendingLoad() {
    if (!this._pendingImage) return

    this._pendingImage.onload = null
    this._pendingImage.onerror = null
    this._pendingImage.src = ''
    this._pendingImage = null
  }
}
