import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Records reading progress when a chapter is actually shown.
// Turbo prefetch fetches HTML without connecting Stimulus, so progress only advances on real views.
export default class extends Controller {
  static values = { url: String }

  // Fires on connect (after values init) and whenever the chapter URL changes on morph.
  urlValueChanged() {
    this.record()
  }

  record() {
    if (!this.hasUrlValue || !this.urlValue) return

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    if (!token) return

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": token,
        "X-Requested-With": "XMLHttpRequest"
      },
      credentials: "same-origin"
    })
      .then((response) => {
        if (response.status === 200) Turbo.cache.clear()
      })
      .catch(() => {
        // Ignore network errors; the next real chapter view can retry.
      })
  }
}
