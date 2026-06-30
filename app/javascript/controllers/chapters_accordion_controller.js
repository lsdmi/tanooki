import { Controller } from "@hotwired/stimulus"

/** Fiction TOC accordion: expand/collapse volume sections and lazy-load chapter lists. */
export default class extends Controller {
  connect() {
    this.openDefaultSections()
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
    if (event.target.closest("[data-epub-download-target]")) return

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

    const url = this.buildChapterSectionUrl(baseUrl, extraParams)
    const placeholder = container.querySelector(".chapter-section-placeholder")
    if (placeholder) {
      placeholder.textContent = "Завантаження…"
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
        if (placeholder) {
          placeholder.textContent = "Не вдалося завантажити розділи. Спробуйте ще раз."
        }
        return
      }
      const html = await response.text()
      if (!html.includes("<li")) {
        if (placeholder) {
          placeholder.textContent = "Розділів не знайдено."
        }
        return
      }
      container.innerHTML = html
      container.dataset.chapterSectionLoaded = "true"
    } catch (error) {
      if (error.name === "AbortError") return

      if (placeholder) {
        placeholder.textContent = "Не вдалося завантажити розділи. Спробуйте ще раз."
      }
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
