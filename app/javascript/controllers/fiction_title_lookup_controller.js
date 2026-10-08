import { Controller } from "@hotwired/stimulus"

const DEBOUNCE_MS = 300
const MIN_QUERY_LENGTH = 2

// Asks /fictions/lookup while the title or English title is typed and replaces the suggestion list.
export default class extends Controller {
  static targets = ["results"]
  static values = { url: String }

  disconnect() {
    this.clearPendingSearch()
  }

  schedule(event) {
    this.pendingQuery = event.target.value.trim()
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.fetchMatches(), DEBOUNCE_MS)
  }

  async fetchMatches() {
    const query = this.pendingQuery || ""
    if (!this.hasResultsTarget) return

    if (query.length < MIN_QUERY_LENGTH) {
      this.resultsTarget.replaceChildren()
      return
    }

    this.abort()
    this.abortController = new AbortController()
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", query)

    try {
      const response = await fetch(url, {
        headers: { Accept: "text/html" },
        signal: this.abortController.signal
      })
      if (!response.ok) return

      this.resultsTarget.innerHTML = await response.text()
    } catch (error) {
      if (error.name === "AbortError") return
    }
  }

  clearPendingSearch() {
    clearTimeout(this.timer)
    this.abort()
  }

  abort() {
    this.abortController?.abort()
    this.abortController = null
  }
}
