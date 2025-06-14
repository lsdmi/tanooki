import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, id: String }
  static targets = ["spinner"]

  connect() {
    this.element.addEventListener('lazy-bg:load', () => {
      this.load();
    });
  }      

  load() {
    const bgUrl = this.urlValue
    const spinner = this.spinnerTarget
    const bgDiv = this.element

    if (!bgUrl || !spinner || !bgDiv) {
      return;
    }

    const img = new window.Image()
    img.src = bgUrl
    img.onload = () => {
      bgDiv.style.backgroundImage = `url('${bgUrl}')`
      spinner.classList.add("hidden")
      bgDiv.classList.add("transition-opacity", "duration-700", "opacity-100")
    }
    img.onerror = () => {
      spinner.classList.add("hidden")
    }
  }
}
