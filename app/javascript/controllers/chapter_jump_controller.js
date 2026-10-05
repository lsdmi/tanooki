import { Controller } from "@hotwired/stimulus"

const HIGHLIGHT_CLASSES = ["bg-brand-subtle", "ring-1", "ring-inset", "ring-brand"]
const HIGHLIGHT_MS = 2000

/**
 * «Перейти до розділу» on the fiction page Chapters tab: the server finds the chapter's group and renders a window
 * of rows around it; the accordion opens that group with the window, and the row is brought up and highlighted.
 */
export default class extends Controller {
  static targets = ["input", "clear", "error"]
  static values = { url: String, failed: String }

  disconnect() {
    this.abortController?.abort()
    clearTimeout(this.highlightTimer)
  }

  edit() {
    this.clearTarget.classList.toggle("hidden", this.inputTarget.value === "")
    this.showError(null)
  }

  clear() {
    this.inputTarget.value = ""
    this.edit()
    this.inputTarget.focus()
  }

  async jump(event) {
    event.preventDefault()
    const number = this.inputTarget.value.trim()
    if (number === "") return

    this.abortController?.abort()
    this.abortController = new AbortController()
    const url = new URL(this.urlValue, window.location.href)
    url.searchParams.set("number", number)

    try {
      const response = await fetch(url, {
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
        credentials: "same-origin",
        signal: this.abortController.signal,
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const result = await response.json()
      if (result.error) {
        this.showError(result.error)
      } else {
        this.open(result)
      }
    } catch (error) {
      if (error.name === "AbortError") return

      this.showError(this.failedValue)
    } finally {
      this.abortController = null
    }
  }

  open({ section_key: sectionKey, target_index: targetIndex, html }) {
    const accordion = this.accordion
    const content = accordion?.openSection(sectionKey, html)
    const list = content?.querySelector("[data-chapter-group-pager-target='list']")
    const row = list && Array.from(list.children).filter((node) => node.tagName === "LI")[targetIndex]
    if (!row) return

    this.inputTarget.blur()
    requestAnimationFrame(() => {
      accordion.revealRow(row)
      this.highlight(row.firstElementChild)
    })
  }

  highlight(element) {
    if (!element) return

    const added = HIGHLIGHT_CLASSES.filter((name) => !element.classList.contains(name))
    element.classList.add(...added)
    clearTimeout(this.highlightTimer)
    this.highlightTimer = setTimeout(() => element.classList.remove(...added), HIGHLIGHT_MS)
  }

  showError(message) {
    this.errorTarget.textContent = message ?? ""
    this.errorTarget.classList.toggle("hidden", !message)
    if (message) {
      this.inputTarget.setAttribute("aria-invalid", "true")
    } else {
      this.inputTarget.removeAttribute("aria-invalid")
    }
  }

  get accordion() {
    const root = this.element.querySelector("[data-chapters-accordion-root]")
    return root && this.application.getControllerForElementAndIdentifier(root, "chapters-accordion")
  }
}
