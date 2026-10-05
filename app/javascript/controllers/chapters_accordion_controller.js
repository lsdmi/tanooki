import { Controller } from "@hotwired/stimulus"

const CHAPTERS_TAB = "chapters"
const TOP_GAP = 16

/**
 * Fiction TOC accordion: expand/collapse volume sections and lazy-load chapter lists.
 * On the fiction page the server opens the group with the continue chapter; `focusRow` is that row's id, brought
 * up under the sticky tabs whenever the reader asks for the Chapters tab (a tab click or a `#chapters` link).
 */
export default class extends Controller {
  static values = { focusRow: String }

  connect() {
    this.openDefaultSections()
    // Once per visit: the list reconnects after a sort, and that should not move the page.
    if (this.focusRowValue && location.hash === `#${CHAPTERS_TAB}` && !document.body.dataset.chapterListRevealed) {
      requestAnimationFrame(() => this.revealFocusRow())
    }
  }

  tabActivated(event) {
    if (event.detail.id !== CHAPTERS_TAB || !this.focusRowValue) return

    requestAnimationFrame(() => this.revealFocusRow())
  }

  // The whole group when its header and the row fit on screen together, otherwise the row with one row above it.
  revealFocusRow() {
    const row = document.getElementById(this.focusRowValue)
    if (!row || !row.offsetParent) return

    document.body.dataset.chapterListRevealed = "true"
    const tabs = document.querySelector("[data-tabs-target='list']")
    const top = (tabs?.getBoundingClientRect().height ?? 0) + TOP_GAP
    const rowRect = row.getBoundingClientRect()
    if (rowRect.top >= top && rowRect.bottom <= window.innerHeight) return

    const headerTop = row.closest(".accordion")?.querySelector(".accordion-header")?.getBoundingClientRect().top
    const target = headerTop !== undefined && rowRect.bottom - headerTop + top <= window.innerHeight
      ? headerTop
      : rowRect.top - rowRect.height - 8
    window.scrollBy({ top: target - top, behavior: "instant" })
  }

  disconnect() {
    this.abortPendingSectionFetch()
    this.resetChapterSectionLoadedState()
  }

  /** Re-run after chapter drawer injects accordion HTML (legacy hook). */
  initializeSections() {
    this.openDefaultSections()
  }

  openDefaultSections() {
    if (!this.element.hasAttribute("data-chapters-accordion-default-open")) return

    this.element.querySelectorAll(".accordion-content:not(.hidden)").forEach((content) => {
      this.loadLazyChapterSection(content)
    })
  }

  toggle(event) {
    // The EPUB button swaps its own markup on click, so by now event.target may be detached and closest() misses it.
    if (event.composedPath().some((node) => node instanceof Element && node.matches("[data-epub-download-target]"))) return

    const container = event.currentTarget.closest(".accordion")
    if (!container) return

    event.preventDefault()

    const icon = container.querySelector(".accordion-icon")
    const content = container.querySelector(".accordion-content")
    if (!icon || !content) return

    const wasHidden = content.classList.contains("hidden")
    content.classList.toggle("hidden")
    icon.classList.toggle("rotate-180")
    event.currentTarget.setAttribute("aria-expanded", wasHidden ? "true" : "false")

    if (wasHidden) {
      this.loadLazyChapterSection(content)
    }

    this.element.querySelectorAll(".accordion").forEach((otherContainer) => {
      if (otherContainer === container) return

      const otherContent = otherContainer.querySelector(".accordion-content")
      const otherIcon = otherContainer.querySelector(".accordion-icon")
      otherContent?.classList.add("hidden")
      otherIcon?.classList.remove("rotate-180")
      otherContainer.querySelector(".accordion-header")?.setAttribute("aria-expanded", "false")
    })
  }

  async loadLazyChapterSection(content) {
    const container = content.querySelector("[data-chapter-section-url]")
    if (!container || container.dataset.chapterSectionLoaded === "true") return

    const baseUrl = container.dataset.chapterSectionUrl
    if (!baseUrl) return

    if (container.dataset.chapterSectionLoading === "true") return

    container.dataset.chapterSectionLoading = "true"

    let extraParams = {}
    try {
      extraParams = JSON.parse(container.dataset.chapterSectionParams || "{}")
    } catch {
      extraParams = {}
    }

    const { chapterSectionPageSize, chapterSectionMobilePageSize } = container.dataset
    if (chapterSectionPageSize) {
      extraParams.limit = window.matchMedia("(min-width: 768px)").matches ? chapterSectionPageSize : chapterSectionMobilePageSize
    }

    const url = this.buildChapterSectionUrl(baseUrl, extraParams)
    let placeholder = container.querySelector(".chapter-section-placeholder")
    // The fiction page shows skeleton rows instead; only the drawer's text placeholder needs a loading message.
    if (placeholder?.tagName === "P") {
      placeholder.textContent = "Завантаження…"
    }
    const showMessage = (text) => {
      if (!placeholder) return
      if (placeholder.tagName !== "P") {
        const message = document.createElement("p")
        message.className = "px-4 py-3 text-sm text-fg-muted chapter-section-placeholder"
        placeholder.replaceWith(message)
        placeholder = message
      }
      placeholder.textContent = text
    }

    this.abortPendingSectionFetch()
    this.sectionAbortController = new AbortController()

    try {
      const response = await fetch(url, {
        headers: { Accept: "text/html", "X-Requested-With": "XMLHttpRequest" },
        credentials: "same-origin",
        signal: this.sectionAbortController.signal,
      })
      if (!response.ok) {
        showMessage("Не вдалося завантажити розділи. Спробуйте ще раз.")
        return
      }
      const html = await response.text()
      if (!html.includes("<li")) {
        showMessage("Розділів не знайдено.")
        return
      }
      container.innerHTML = html
      container.dataset.chapterSectionLoaded = "true"
    } catch (error) {
      if (error.name === "AbortError") return

      showMessage("Не вдалося завантажити розділи. Спробуйте ще раз.")
    } finally {
      delete container.dataset.chapterSectionLoading
      this.sectionAbortController = null
    }
  }

  abortPendingSectionFetch() {
    if (!this.sectionAbortController) return

    this.sectionAbortController.abort()
    this.sectionAbortController = null
  }

  resetChapterSectionLoadedState() {
    this.element.querySelectorAll("[data-chapter-section-loaded], [data-chapter-section-loading]").forEach((container) => {
      delete container.dataset.chapterSectionLoaded
      delete container.dataset.chapterSectionLoading
    })
  }

  buildChapterSectionUrl(baseUrl, extraParams) {
    const url = new URL(baseUrl, window.location.href)
    Object.entries(extraParams).forEach(([key, value]) => {
      if (value === null || value === undefined || value === "") return
      url.searchParams.set(key, String(value))
    })
    return `${url.pathname}${url.search}`
  }
}
