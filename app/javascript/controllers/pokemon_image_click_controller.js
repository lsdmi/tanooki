import { Controller } from "@hotwired/stimulus";

// Highlights the selected Pokémon in the party grid while its details load.
export default class PokemonImageClickController extends Controller {
  static targets = [ "button" ]

  select(event) {
    this.buttonTargets.forEach(button => {
      const selected = button === event.currentTarget;
      button.classList.toggle("border-emerald-600", selected);
      button.setAttribute("aria-pressed", selected);
    });
  }
}
