import { Controller } from "@hotwired/stimulus";

// Client-side tabs (fiction page). The server renders the default tab; a URL hash naming another tab
// (`#chapters`) wins on load and on `hashchange`. Picking a tab writes its hash with replaceState, so it
// survives reload and back without adding history entries.
// Studio's tab list also uses this controller with server-rendered links and no targets; then it does nothing.
export default class extends Controller {
  static targets = ["tab", "panel", "list"];
  static values = { activeTab: String };

  connect() {
    if (!this.hasTabTarget) return;

    this.defaultTab = this.activeTabValue;
    const fromHash = this.tabIdFromHash();
    if (fromHash && fromHash !== this.activeTabValue) {
      this.activate(fromHash);
      this.revealList();
    }
  }

  select(event) {
    event.preventDefault();
    this.show(event.currentTarget.dataset.tabId);
  }

  // An in-page link to another tab (the About EPUB card → Chapters). Turbo turns same-page anchor clicks into
  // pushState without `hashchange`, so the link switches the tab itself.
  jump(event) {
    event.preventDefault();
    this.show(event.params.tab);
    this.revealList();
  }

  navigate(event) {
    const tabs = this.tabTargets;
    const index = tabs.indexOf(event.currentTarget);
    const next = {
      ArrowRight: tabs[(index + 1) % tabs.length],
      ArrowLeft: tabs[(index - 1 + tabs.length) % tabs.length],
      Home: tabs[0],
      End: tabs[tabs.length - 1],
    }[event.key];
    if (!next) return;

    event.preventDefault();
    this.show(next.dataset.tabId);
    next.focus();
  }

  hashChanged() {
    if (!this.hasTabTarget) return;

    const id = this.tabIdFromHash() || (location.hash ? null : this.defaultTab);
    if (!id || id === this.activeTabValue) return;

    this.activate(id);
    if (id !== this.defaultTab) this.revealList();
  }

  show(id) {
    this.activate(id);
    history.replaceState(history.state, "", `#${id}`);
  }

  activate(id) {
    this.activeTabValue = id;
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.tabId === id;
      tab.setAttribute("aria-selected", active);
      tab.tabIndex = active ? 0 : -1;
    });
    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.tabId !== id;
    });
    this.dispatch("activated", { detail: { id } });
  }

  tabIdFromHash() {
    const id = decodeURIComponent(location.hash.slice(1));
    return this.tabTargets.some((tab) => tab.dataset.tabId === id) ? id : null;
  }

  // A link to a non-default tab (comment notification, the reader's «back») is for that panel, so bring it up
  // when most of the screen is still above it, or when it has scrolled away above.
  revealList() {
    if (!this.hasListTarget) return;

    const { top, bottom } = this.listTarget.getBoundingClientRect();
    if (top < 0 || bottom > window.innerHeight * 0.6) this.listTarget.scrollIntoView({ block: "start" });
  }
}
