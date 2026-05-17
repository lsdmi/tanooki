import { Controller } from "@hotwired/stimulus";
import { acknowledgeAdultContent } from "adult_content_disclaimer";

/** Dismissible 18+ disclaimer; acknowledgement is stored in the Rails session. */
export default class extends Controller {
  dismiss() {
    this.hide();
    acknowledgeAdultContent().catch(() => {});
  }

  hide() {
    this.element.classList.add("hidden");
    this.element.setAttribute("hidden", "");
  }
}
