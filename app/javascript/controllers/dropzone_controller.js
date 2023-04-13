import { Controller } from "@hotwired/stimulus";

export default class DropzoneController extends Controller {
  static targets = ["output"];

  connect() {
    console.log("DropzoneController connected");
  }

  update(event) {
    const imageName = document.querySelector("#image_name");
    if (!imageName) return;

    const input = event.target;
    if (input.files && input.files[0]) {
      imageName.textContent = input.files[0].name.slice(0, 40);
    }
  }
}
