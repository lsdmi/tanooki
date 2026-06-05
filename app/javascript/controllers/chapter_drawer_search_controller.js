import { Controller } from "@hotwired/stimulus"

/** Filters the reader chapter list by number or title (full fiction index, not lazy sections only). */
export default class extends Controller {
  static targets = ["input", "results", "resultsList", "list", "empty"]
  static values = { chapters: Array }

  connect() {
    this.filter = this.filter.bind(this)
  }

  filter() {
    const query = this.inputTarget.value.trim()
    if (!query) {
      this.showList()
      return
    }

    const normalized = query.toLowerCase()
    const digits = normalized.replace(/[^\d.]/g, "")
    const matches = this.chaptersValue.filter((chapter) =>
      this.chapterMatches(chapter, normalized, digits)
    )

    this.hideList()
    this.renderResults(matches)
  }

  clear() {
    if (!this.hasInputTarget) return

    this.inputTarget.value = ""
    this.showList()
  }

  chapterMatches(chapter, normalized, digits) {
    const title = chapter.title.toLowerCase()
    if (title.includes(normalized)) return true
    if (digits && String(chapter.number).includes(digits.replace(/\./g, ""))) return true
    if (digits && title.includes(digits)) return true

    return false
  }

  showList() {
    this.listTarget.classList.remove("hidden")
    this.resultsTarget.classList.add("hidden")
    this.emptyTarget.classList.add("hidden")
  }

  hideList() {
    this.listTarget.classList.add("hidden")
    this.resultsTarget.classList.remove("hidden")
  }

  renderResults(matches) {
    this.resultsListTarget.replaceChildren()

    if (matches.length === 0) {
      this.emptyTarget.classList.remove("hidden")
      return
    }

    this.emptyTarget.classList.add("hidden")

    const fragment = document.createDocumentFragment()
    matches.forEach((chapter) => {
      fragment.appendChild(this.buildResultRow(chapter))
    })
    this.resultsListTarget.appendChild(fragment)
  }

  buildResultRow(chapter) {
    const row = document.createElement("li")
    row.className = "group"

    if (chapter.current) {
      const current = document.createElement("div")
      current.className =
        "border-l-2 border-cyan-600 bg-cyan-50/80 px-4 py-3 dark:border-rose-500 dark:bg-rose-950/40"
      current.setAttribute("aria-current", "page")
      const label = document.createElement("span")
      label.className = "block truncate text-sm font-medium text-cyan-900 dark:text-rose-200"
      label.textContent = chapter.title
      current.appendChild(label)
      row.appendChild(current)
      return row
    }

    const link = document.createElement("a")
    link.href = chapter.url
    link.className =
      "block px-4 py-3 transition-colors hover:bg-stone-50 dark:hover:bg-zinc-800/60"
    link.dataset.turbo = "false"
    const label = document.createElement("span")
    label.className = "block truncate text-sm text-stone-700 dark:text-zinc-300"
    label.textContent = chapter.title
    link.appendChild(label)
    row.appendChild(link)

    return row
  }
}
