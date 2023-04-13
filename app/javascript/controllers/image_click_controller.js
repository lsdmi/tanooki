import { Controller } from "@hotwired/stimulus";

export default class ImageClickController extends Controller {
  static targets = [ "output" ]

  connect() {
    console.log("ImageClickController connected")
  }

  addSelected(event) {
    const allImgs = document.querySelectorAll("img");

    const clickedImg = event.target;
    const clickedImgAvatarId = clickedImg.dataset.avatarId;

    allImgs.forEach(img => {
      img.classList.remove("selected-image");
    });

    clickedImg.classList.add("selected-image");
    document.getElementById("user_avatar_id").value = clickedImgAvatarId;
  }
}
