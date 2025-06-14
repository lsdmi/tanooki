import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { url: String, id: String }

  connect() {
    this.element.addEventListener('lazy-bg:load', () => {
      this.load();
    });
  }

  load() {
    const bgUrl = this.urlValue;
    const bgDiv = this.element;

    if (!bgUrl || !bgDiv) {
      return;
    }

    const img = new window.Image();
    img.src = bgUrl;
    img.onload = () => {
      bgDiv.style.backgroundImage = `url('${bgUrl}')`;
      bgDiv.classList.add("transition-opacity", "duration-700", "opacity-100");
      bgDiv.dispatchEvent(new CustomEvent("lazy-bg:loaded", { bubbles: true }));
    }
    img.onerror = () => {
      bgDiv.dispatchEvent(new CustomEvent("lazy-bg:error", { bubbles: true }));
    }
  }
}
