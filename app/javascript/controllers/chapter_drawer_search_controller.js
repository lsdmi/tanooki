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
    const status = chapter.status || (chapter.current ? "current" : "unread")

    if (status === "current") {
      const current = document.createElement("div")
      current.className =
        "flex items-center gap-3 border-l-2 border-cyan-600 bg-cyan-50/80 px-4 py-3 dark:border-rose-500 dark:bg-rose-950/40"
      current.setAttribute("aria-current", "page")
      current.appendChild(this.buildTitle(chapter.title, status))
      current.appendChild(this.buildStatusIcon(status))
      row.appendChild(current)
      return row
    }

    const link = document.createElement("a")
    link.href = chapter.url
    link.className =
      "flex items-center gap-3 px-4 py-3 transition-colors hover:bg-stone-50 dark:hover:bg-zinc-800/60"
    link.dataset.turbo = "false"
    link.appendChild(this.buildTitle(chapter.title, status))
    link.appendChild(this.buildStatusIcon(status))
    row.appendChild(link)

    return row
  }

  buildTitle(title, status) {
    const label = document.createElement("span")
    label.className = `min-w-0 flex-1 truncate ${this.titleClass(status)}`
    label.textContent = title
    return label
  }

  titleClass(status) {
    if (status === "current") return "text-sm font-medium text-cyan-900 dark:text-rose-200"
    if (status === "read") return "text-sm text-stone-700 dark:text-zinc-300"
    return "text-sm text-stone-400 dark:text-zinc-500"
  }

  buildStatusIcon(status) {
    const icon = document.createElement("span")
    icon.className = "inline-flex h-5 w-5 shrink-0 items-center justify-center"
    icon.setAttribute("aria-hidden", "true")

    if (status === "read") {
      icon.classList.add("text-emerald-500", "dark:text-emerald-400")
      icon.innerHTML =
        '<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" /></svg>'
    } else if (status === "current") {
      icon.classList.add("text-cyan-600", "dark:text-rose-400")
      icon.innerHTML =
        '<svg class="h-5 w-5" viewBox="0 0 20 20" fill="none"><circle cx="10" cy="10" r="7.25" stroke="currentColor" stroke-width="1.5" stroke-dasharray="3 2" /><circle cx="10" cy="10" r="2.5" fill="currentColor" /></svg>'
    } else {
      icon.classList.add("text-stone-300", "dark:text-zinc-600")
      icon.innerHTML =
        '<svg class="h-5 w-5" viewBox="0 0 20 20" fill="none"><circle cx="10" cy="10" r="7.25" stroke="currentColor" stroke-width="1.5" /></svg>'
    }

    return icon
  }
}
