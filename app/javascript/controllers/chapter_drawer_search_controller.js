import { Controller } from "@hotwired/stimulus"

/** Filters the reader chapter list by number or title (full fiction index, not lazy sections only). */
export default class extends Controller {
  static targets = ["input", "results", "resultsList", "list", "empty", "row"]
  static values = { chapters: Array, labels: Object }

  connect() {
    this.filter = this.filter.bind(this)
  }

  // The chapters value is built at page load; a read toggle re-renders only its list rows,
  // so results take the status from the latest row for that chapter.
  rowTargetConnected(row) {
    this.statusById ??= new Map()
    this.statusById.set(row.dataset.chapterId, row.dataset.chapterStatus)
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

  disconnect() {
    this.clear()
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
    const status = this.statusFor(chapter)

    if (status === "current") {
      const current = document.createElement("div")
      current.className =
        "flex items-center gap-3 border-l-2 border-brand bg-brand-subtle px-4 py-3"
      current.setAttribute("aria-current", "page")
      current.appendChild(this.buildTitle(chapter.title, status))
      current.appendChild(this.buildStatusIcon(status))
      row.appendChild(current)
      return row
    }

    const link = document.createElement("a")
    link.href = chapter.url
    link.className = `flex items-center gap-3 px-4 py-3 transition-colors ${this.rowClass(status)}`
    link.dataset.turbo = "false"
    link.appendChild(this.buildTitle(chapter.title, status))
    link.appendChild(this.buildStatusIcon(status))
    row.appendChild(link)

    return row
  }

  statusFor(chapter) {
    if (chapter.status === "current") return "current"

    return this.statusById?.get(String(chapter.id)) || chapter.status || "unread"
  }

  buildTitle(title, status) {
    const label = document.createElement("span")
    label.className = `min-w-0 flex-1 truncate ${this.titleClass(status)}`
    label.textContent = title
    return label
  }

  // Mirrors Chapters::ChapterDrawerHelper: only read rows are washed and muted.
  titleClass(status) {
    if (status === "current") return "text-sm font-medium text-fg-brand-hover"
    if (status === "in_progress") return "text-sm font-medium text-fg"
    if (status === "read") return "text-sm text-fg-muted"
    return "text-sm text-fg"
  }

  rowClass(status) {
    if (status === "read") return "bg-surface hover:bg-surface-strong dark:bg-surface/40 dark:hover:bg-surface/70"
    return "hover:bg-surface dark:hover:bg-surface/60"
  }

  buildStatusIcon(status) {
    const icon = document.createElement("span")
    icon.className = "inline-flex h-5 w-5 shrink-0 items-center justify-center"
    const label = this.labelsValue[status]
    if (label) {
      icon.setAttribute("role", "img")
      icon.setAttribute("aria-label", label)
    } else {
      icon.setAttribute("aria-hidden", "true")
    }

    if (status === "read") {
      icon.classList.add("text-emerald-500", "dark:text-emerald-400")
      icon.innerHTML =
        '<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" /></svg>'
    } else if (status === "current" || status === "in_progress") {
      icon.classList.add("text-fg-brand")
      icon.innerHTML =
        '<svg class="h-5 w-5" viewBox="0 0 20 20" fill="none"><circle cx="10" cy="10" r="7.25" stroke="currentColor" stroke-width="1.5" stroke-dasharray="3 2" /><circle cx="10" cy="10" r="2.5" fill="currentColor" /></svg>'
    } else {
      icon.classList.add("text-fg-subtle")
      icon.innerHTML =
        '<svg class="h-5 w-5" viewBox="0 0 20 20" fill="none"><circle cx="10" cy="10" r="7.25" stroke="currentColor" stroke-width="1.5" /></svg>'
    }

    return icon
  }
}
