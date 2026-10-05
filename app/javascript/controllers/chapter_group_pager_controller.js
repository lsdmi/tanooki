import { Controller } from "@hotwired/stimulus"

const DESKTOP_QUERY = "(min-width: 768px)"
const SKELETON_ROWS = 4

/**
 * Fiction page chapter group: «Показати ще N» appends the next page of rows, «Показати всі» loads the rest.
 * A jump to a chapter renders a window from `start`; «Показати 1–40» above it loads the rows before the window.
 */
export default class extends Controller {
  static targets = ["list", "before", "footer", "more", "moreLabel", "remaining", "all", "error", "skeleton"]
  static values = {
    url: String,
    total: Number,
    start: Number,
    pageSize: Number,
    mobilePageSize: Number,
    labels: Object,
  }

  connect() {
    this.media = window.matchMedia(DESKTOP_QUERY)
    this.trimToFirstPage()
    this.render = this.render.bind(this)
    this.media.addEventListener("change", this.render)
    this.render()
  }

  disconnect() {
    this.media?.removeEventListener("change", this.render)
    this.abortController?.abort()
  }

  more() {
    this.load(this.currentPageSize)
  }

  all() {
    this.load(null)
  }

  get currentPageSize() {
    return this.media.matches ? this.pageSizeValue : this.mobilePageSizeValue
  }

  get rows() {
    return Array.from(this.listTarget.querySelectorAll(":scope > li:not([data-skeleton])"))
  }

  get remaining() {
    return Math.max(this.totalValue - this.startValue - this.rows.length, 0)
  }

  // The server renders the desktop page; a phone keeps only its own first page so «Показати ще» continues from there.
  // Without the trim class the page was grown to reach the continue row, and phones keep all of it.
  trimToFirstPage() {
    const trim = "max-md:[&>li:nth-child(n+11)]:hidden"
    if (!this.listTarget.classList.contains(trim)) return

    if (!this.media.matches) {
      this.rows.slice(this.mobilePageSizeValue).forEach((row) => row.remove())
    }
    this.listTarget.classList.remove(trim)
  }

  render() {
    const remaining = this.remaining
    this.footerTarget.classList.toggle("hidden", remaining === 0)
    if (remaining === 0) return

    const pageSize = this.currentPageSize
    const showAll = remaining > pageSize
    this.moreLabelTarget.textContent = this.format(this.labelsValue.more, Math.min(remaining, pageSize))
    this.remainingTarget.textContent = this.format(this.pluralLabel(this.labelsValue.remaining, remaining), remaining)
    this.remainingTarget.classList.toggle("hidden", !showAll)
    this.allTarget.classList.toggle("hidden", !showAll)
  }

  async load(limit) {
    if (this.abortController) return

    const url = this.pageUrl(this.startValue + this.rows.length, limit)

    this.abortController = new AbortController()
    this.errorTarget.classList.add("hidden")
    this.footerTarget.classList.add("hidden")
    const skeletons = this.showSkeletons(Math.min(limit ?? this.remaining, this.remaining, SKELETON_ROWS))

    try {
      const response = await this.fetchRows(url)
      const added = this.append(await response.text())
      // Fewer rows than asked means the group shrank since the page loaded (a chapter was hidden or deleted).
      if (limit === null || added < limit) this.totalValue = this.startValue + this.rows.length
    } catch (error) {
      if (error.name === "AbortError") return

      this.errorTarget.textContent = this.labelsValue.failed
      this.errorTarget.classList.remove("hidden")
    } finally {
      skeletons.forEach((row) => row.remove())
      this.abortController = null
      this.render()
    }
  }

  // The window stays where it is on screen; the rows above grow out of view and the reader scrolls up to them.
  async before() {
    if (this.abortController || !this.hasBeforeTarget) return

    const anchor = this.rows[0]
    const button = this.beforeTarget.querySelector("button")
    this.abortController = new AbortController()
    this.errorTarget.classList.add("hidden")
    button.disabled = true

    try {
      // The rows above can be more than one request's page in a long volume; take the group head and keep `start`.
      const response = await this.fetchRows(this.pageUrl(0, null))
      const fetched = this.parseRows(await response.text()).slice(0, this.startValue)
      const top = anchor?.getBoundingClientRect().top
      this.beforeTarget.remove()
      this.listTarget.prepend(...fetched.filter((row) => !row.id || !document.getElementById(row.id)))
      if (anchor) window.scrollBy(0, anchor.getBoundingClientRect().top - top)
      this.startValue = 0
    } catch (error) {
      if (error.name === "AbortError") return

      this.errorTarget.textContent = this.labelsValue.failed
      this.errorTarget.classList.remove("hidden")
    } finally {
      button.disabled = false
      this.abortController = null
    }
  }

  pageUrl(offset, limit) {
    const url = new URL(this.urlValue, window.location.href)
    url.searchParams.set("offset", offset)
    url.searchParams.set("limit", limit ?? "all")
    return url
  }

  async fetchRows(url) {
    const response = await fetch(url, {
      headers: { Accept: "text/html", "X-Requested-With": "XMLHttpRequest" },
      credentials: "same-origin",
      signal: this.abortController.signal,
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response
  }

  parseRows(html) {
    const template = document.createElement("template")
    template.innerHTML = html
    return Array.from(template.content.children).filter((row) => row.tagName === "LI")
  }

  append(html) {
    const fetched = this.parseRows(html)
    // A chapter published since the last page shifts the offsets; skip rows that are already shown.
    this.listTarget.append(...fetched.filter((row) => !row.id || !document.getElementById(row.id)))
    return fetched.length
  }

  showSkeletons(count) {
    return Array.from({ length: count }, () => {
      const row = this.skeletonTarget.content.firstElementChild.cloneNode(true)
      row.setAttribute("data-skeleton", "")
      this.listTarget.append(row)
      return row
    })
  }

  pluralLabel(forms, count) {
    return forms[new Intl.PluralRules("uk").select(count)] ?? forms.other
  }

  format(label, count) {
    return label.replace("%{count}", count)
  }
}
