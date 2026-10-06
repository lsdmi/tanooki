import { Controller } from "@hotwired/stimulus"

const HIGHLIGHT_CLASSES = ["bg-brand-subtle", "ring-1", "ring-inset", "ring-brand"]
const HIGHLIGHT_MS = 2000

/**
 * «Перейти до розділу» on the fiction page Chapters tab: the server finds the chapter's group and renders a window
 * of rows around it; the accordion opens that group with the window, and the row is brought up and highlighted.
 *
 * The «До поточного розділу» chip shows while the reader is in the list and the continue row is off screen (scrolled
 * away, in a collapsed group, or swapped out by a jump); its arrow points at the row or its group. A click brings the
 * row back the same way, loading its window when it is not on the page.
 */
export default class extends Controller {
  static targets = ["input", "clear", "error", "chip", "chipUp", "chipDown"]
  static values = { url: String, failed: String, continueId: Number, continueSection: String }

  disconnect() {
    this.abortController?.abort()
    clearTimeout(this.highlightTimer)
  }

  chipTargetConnected() {
    this.observer = new MutationObserver(() => this.track())
    this.observer.observe(this.element, { childList: true, subtree: true, attributeFilter: ["class"] })
    this.track()
  }

  chipTargetDisconnected() {
    this.observer?.disconnect()
    cancelAnimationFrame(this.trackFrame)
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

  jump(event) {
    event.preventDefault()
    const number = this.inputTarget.value.trim()
    if (number === "") return

    this.request({ number }, true)
  }

  toCurrent() {
    const row = this.continueRow
    if (row?.offsetParent) {
      this.reveal(row)
    } else {
      this.request({ chapter_id: this.continueIdValue }, false)
    }
  }

  async request(params, fromField) {
    this.abortController?.abort()
    this.abortController = new AbortController()
    const url = new URL(this.urlValue, window.location.href)
    Object.entries(params).forEach(([key, value]) => url.searchParams.set(key, value))

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
        this.open(result, fromField)
      }
    } catch (error) {
      if (error.name === "AbortError") return

      this.showError(this.failedValue)
    } finally {
      this.abortController = null
    }
  }

  open({ section_key: sectionKey, target_index: targetIndex, html }, fromField) {
    const content = this.accordion?.openSection(sectionKey, html)
    const list = content?.querySelector("[data-chapter-group-pager-target='list']")
    const row = list && Array.from(list.children).filter((node) => node.tagName === "LI")[targetIndex]
    if (!row) return

    if (fromField) this.inputTarget.blur()
    requestAnimationFrame(() => this.reveal(row))
  }

  reveal(row) {
    this.accordion.revealRow(row)
    this.highlight(row.firstElementChild)
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

  track() {
    if (!this.hasChipTarget || this.trackFrame) return

    this.trackFrame = requestAnimationFrame(() => {
      this.trackFrame = null
      const direction = this.chipDirection()
      this.chipTarget.hidden = !direction
      this.chipUpTarget.hidden = direction !== "up"
      this.chipDownTarget.hidden = direction !== "down"
    })
  }

  // Only once the list has come up past the middle of the screen: on the hero the «Продовжити» button is enough.
  chipDirection() {
    const root = this.element.querySelector("[data-chapters-accordion-root]")
    if (!root?.offsetParent) return null

    const tabs = this.accordion?.tabsHeight ?? 0
    const list = root.getBoundingClientRect()
    if (list.top > window.innerHeight / 2 || list.bottom < tabs) return null

    const row = this.continueRow
    const target = row?.offsetParent ? row : this.continueGroup
    if (!target) return null

    const rect = target.getBoundingClientRect()
    if (target === row && rect.top >= tabs && rect.bottom <= window.innerHeight) return null
    if (rect.bottom <= tabs) return "up"
    if (rect.top >= window.innerHeight) return "down"
    return rect.top < window.innerHeight / 2 ? "up" : "down"
  }

  get continueRow() {
    return document.getElementById(`chapter_list_chapter_${this.continueIdValue}`)
  }

  get continueGroup() {
    return Array.from(this.element.querySelectorAll(".accordion")).find(
      (node) => node.dataset.sectionKey === this.continueSectionValue,
    )
  }

  get accordion() {
    const root = this.element.querySelector("[data-chapters-accordion-root]")
    return root && this.application.getControllerForElementAndIdentifier(root, "chapters-accordion")
  }
}
