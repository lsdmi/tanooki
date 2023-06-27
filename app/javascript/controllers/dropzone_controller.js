import { Controller } from "@hotwired/stimulus";

export default class DropzoneController extends Controller {
  static targets = ["output"];

  connect() {
    console.log("DropzoneController connected");

    const targetIds = [
      "advertisement_cover",
      "advertisement_poster",
      "fictions_cover",
      "publication_cover"
    ];

    targetIds.forEach(targetId => {
      const element = document.getElementById(targetId);
      if (element) this.setTextContent(element);
    });
  }

  update(event) {
    this.updateTextContent(event.target);
  }

  setTextContent(input) {
    const targetId = input.getAttribute("id");
    const targetElement = document.querySelector(`#${targetId}`);

    if (!targetElement || !input.files || !input.files[0]) {
      targetElement.textContent = "";
      return;
    }

    const fileName = input.files[0].name;
    targetElement.textContent = fileName.slice(0, 40);
  }

  updateTextContent(input) {
    const targetId = input.getAttribute("id");
    let targetElement;

    switch(targetId) {
      case 'advertisement_cover':
        targetElement = document.querySelector(`#cover_name`);
        break;
      case 'advertisement_poster':
        targetElement = document.querySelector(`#poster_name`);
        break;
      default:
        targetElement = document.querySelector(`#image_name`);
        break;
    }

    if (!targetElement || !input.files || !input.files[0]) {
      targetElement.textContent = "";
      return;
    }

    const fileName = input.files[0].name;
    targetElement.textContent = fileName.slice(0, 40);
  }
}
