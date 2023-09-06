import { Controller } from "@hotwired/stimulus";

export default class PokemonImageClickController extends Controller {
  static targets = [ "output" ]

  connect() {
    console.log("PokemonImageClickController connected")
  }

  addSelected(event) {
    const allImgs = document.querySelectorAll("img");
    const clickedImg = event.target;

    allImgs.forEach(img => {
      img.parentElement.classList.remove("border-emerald-600");
    });

    clickedImg.parentElement.classList.add("border-emerald-600");
  }
}
