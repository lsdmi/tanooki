import { Controller } from "@hotwired/stimulus";

// File pick surface: keep the input in the a11y tree (sr-only, never display:none /
 // opacity-0 overlay alone — Safari often ignores fully transparent file clicks).
// Clicks on the surface call input.click() from a user gesture.
export default class DropzoneController extends Controller {
  static targets = ["input", "output"];

  static nameElements = {
    fictions_cover: "#cover_name",
    fictions_banner: "#banner_name",
    scanlator_avatar: "#avatar_name",
    scanlator_banner: "#banner_name",
    publication_cover: "#image_name"
  };

  connect() {
    Object.keys(this.constructor.nameElements).forEach((id) => {
      const element = document.getElementById(id);
      if (element) this.refreshName(element);
    });
  }

  open(event) {
    if (!this.hasInputTarget) return;
    if (event.target === this.inputTarget) return;

    event.preventDefault();
    this.inputTarget.click();
  }

  update(event) {
    this.refreshName(event.target);
  }

  refreshName(input) {
    const nameElement = this.nameElementFor(input);
    if (!nameElement) return;

    const file = input.files?.[0];
    nameElement.textContent = file ? file.name.slice(0, 40) : "";
  }

  nameElementFor(input) {
    const selector = this.constructor.nameElements[input.id] || "#image_name";
    return this.element.querySelector(selector) || document.querySelector(selector);
  }
}
