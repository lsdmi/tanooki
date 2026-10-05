import { Controller } from "@hotwired/stimulus";

// Highlights the selected Pokémon in the party grid while its details load.
export default class PokemonImageClickController extends Controller {
  static targets = [ "button" ]

  select(event) {
    this.buttonTargets.forEach(button => {
      button.setAttribute("aria-pressed", button === event.currentTarget);
    });
  }
}
