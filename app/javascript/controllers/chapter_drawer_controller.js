import { Controller } from "@hotwired/stimulus";

/** Slide-out chapter list on the chapter reader (mobile). */
export default class extends Controller {
  static targets = ["backdrop", "panel"];

  connect() {
    this._onEscape = this._onEscape.bind(this);
    this._onTurboLoad = () => this.close();
    document.addEventListener("turbo:load", this._onTurboLoad);
  }

  disconnect() {
    document.removeEventListener("turbo:load", this._onTurboLoad);
    document.removeEventListener("keydown", this._onEscape);
    document.body.classList.remove("overflow-hidden");
  }

  open() {
    if (!this.hasBackdropTarget || !this.hasPanelTarget) return;

    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none");
    this.backdropTarget.classList.add("opacity-100", "pointer-events-auto");
    this.backdropTarget.setAttribute("aria-hidden", "false");

    this.panelTarget.classList.remove("-translate-x-full");

    document.body.classList.add("overflow-hidden");
    document.addEventListener("keydown", this._onEscape);

    if (typeof window.initializeAccordion === "function") {
      window.requestAnimationFrame(() => window.initializeAccordion());
    }
  }

  close() {
    if (!this.hasBackdropTarget || !this.hasPanelTarget) return;

    this.backdropTarget.classList.add("opacity-0", "pointer-events-none");
    this.backdropTarget.classList.remove("opacity-100", "pointer-events-auto");
    this.backdropTarget.setAttribute("aria-hidden", "true");

    this.panelTarget.classList.add("-translate-x-full");

    document.body.classList.remove("overflow-hidden");
    document.removeEventListener("keydown", this._onEscape);
  }

  _onEscape(event) {
    if (event.key === "Escape") this.close();
  }
}
