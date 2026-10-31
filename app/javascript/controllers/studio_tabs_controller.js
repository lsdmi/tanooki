import { Controller } from "@hotwired/stimulus"

/** Syncs `/studio?tab=` while Turbo Stream switches studio tabs (visit URL stays on the tab endpoint). */
export default class extends Controller {
  static values = {
    active: String,
    path: { type: String, default: "/studio" }
  }

  connect() {
    this.replaceTabParam(this.activeValue)
  }

  select(event) {
    const tab = event.currentTarget.dataset.tab
    if (tab) this.replaceTabParam(tab)
  }

  replaceTabParam(tab) {
    if (!tab) return

    const url = new URL(this.pathValue, window.location.origin)
    url.searchParams.set("tab", tab)
    const next = `${url.pathname}${url.search}`
    if (`${window.location.pathname}${window.location.search}` === next) return

    window.history.replaceState(window.history.state, "", next)
  }
}
