import { Controller } from "@hotwired/stimulus";

export default class DropzoneController extends Controller {
  static targets = ["output"];

  connect() {
    console.log("DropzoneController connected");

    const coverInput = document.getElementById("#image_name");
    if (!coverInput) return;

    this.updateTextContent(coverInput);
  }

  update(event) {
    this.updateTextContent(event.target);
  }

  updateTextContent(input) {
    const imageName = document.querySelector("#image_name");

    if (!imageName || !input.files || !input.files[0]) {
      imageName.textContent = "";
      return;
    }

    const fileName = input.files[0].name;
    imageName.textContent = fileName.slice(0, 40);
  }
}
