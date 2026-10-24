import { Controller } from "@hotwired/stimulus"

const SELECTED = ["ring-2", "ring-brand", "ring-offset-2", "scale-105"]

// Studio portraits. The pink `.selected-image` rule lives on the reader stylesheet, which this page does not load.
export default class extends Controller {
  addSelected() {
    document.querySelectorAll("[data-avatar-id]").forEach((img) => {
      img.classList.remove(...SELECTED)
    })
    this.element.classList.add(...SELECTED)

    const input = document.getElementById("user_avatar_id")
    if (input) input.value = this.element.dataset.avatarId
  }
}
