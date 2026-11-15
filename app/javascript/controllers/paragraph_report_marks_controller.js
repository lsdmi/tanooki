import { Controller } from "@hotwired/stimulus"
import { markParagraphReportQuote, normalizeMarkText } from "paragraph_report_marks"

// Paints open-report quote marks and shows reader messages on hover / click / keyboard.
export default class extends Controller {
  static values = {
    items: { type: Array, default: [] },
    empty: { type: String, default: "" },
    heading: { type: String, default: "" }
  }

  connect() {
    this.content = document.getElementById("user-content")
    if (!this.content) return

    this.messagesByIndex = new Map()
    this.itemsValue.forEach((item) => {
      const index = Number(item.i)
      if (!Number.isInteger(index)) return

      const entries = normalizeEntries(item.m)
      this.messagesByIndex.set(index, entries)

      const block = this.content.querySelector(`[data-rp-i="${index}"]`)
      if (!block) return

      uniqueQuotes(entries).forEach((quote) => markParagraphReportQuote(block, quote))
    })

    this.pinned = false
    this.activeMark = null
    this._onPointerOver = this.onPointerOver.bind(this)
    this._onPointerOut = this.onPointerOut.bind(this)
    this._onClick = this.onClick.bind(this)
    this._onKeydown = this.onKeydown.bind(this)
    this._onDocPointer = this.onDocPointer.bind(this)
    this._onCreated = this.onCreated.bind(this)

    this.content.addEventListener("pointerover", this._onPointerOver)
    this.content.addEventListener("pointerout", this._onPointerOut)
    this.content.addEventListener("click", this._onClick)
    this.content.addEventListener("keydown", this._onKeydown)
    this.content.addEventListener("paragraph-report:created", this._onCreated)
    document.addEventListener("pointerdown", this._onDocPointer)
  }

  disconnect() {
    this.hidePopover()
    this.content?.removeEventListener("pointerover", this._onPointerOver)
    this.content?.removeEventListener("pointerout", this._onPointerOut)
    this.content?.removeEventListener("click", this._onClick)
    this.content?.removeEventListener("keydown", this._onKeydown)
    this.content?.removeEventListener("paragraph-report:created", this._onCreated)
    document.removeEventListener("pointerdown", this._onDocPointer)
  }

  onCreated(event) {
    const index = Number(event.detail?.blockIndex)
    if (!Number.isInteger(index) || index < 0) return

    const entry = {
      u: String(event.detail?.user || "").trim(),
      t: String(event.detail?.message || "").trim(),
      q: String(event.detail?.quote || "").trim()
    }
    const existing = this.messagesByIndex.get(index) || []
    existing.push(entry)
    this.messagesByIndex.set(index, existing)

    const block = this.content?.querySelector(`[data-rp-i="${index}"]`)
    markParagraphReportQuote(block, entry.q)
  }

  onPointerOver(event) {
    if (this.pinned) return
    if (event.pointerType === "touch") return
    const mark = event.target.closest?.(".paragraph-report--marked")
    if (!mark || !this.content.contains(mark)) return
    this.showPopover(mark)
  }

  onPointerOut(event) {
    if (this.pinned) return
    if (event.pointerType === "touch") return
    const mark = event.target.closest?.(".paragraph-report--marked")
    if (!mark || !this.content.contains(mark)) return
    const next = event.relatedTarget
    if (next && (mark.contains(next) || this.popover?.contains(next))) return
    this.hidePopover()
  }

  onClick(event) {
    const mark = event.target.closest?.(".paragraph-report--marked")
    if (!mark || !this.content.contains(mark)) return
    if (this.popover && this.activeMark === mark && this.pinned) {
      this.pinned = false
      this.hidePopover()
      return
    }
    this.pinned = true
    this.showPopover(mark)
  }

  onKeydown(event) {
    if (event.key !== "Enter" && event.key !== " ") return
    const mark = event.target.closest?.(".paragraph-report--marked")
    if (!mark || !this.content.contains(mark)) return
    event.preventDefault()
    this.pinned = true
    this.showPopover(mark)
  }

  onDocPointer(event) {
    if (!this.popover) return
    if (this.popover.contains(event.target)) return
    if (event.target.closest?.(".paragraph-report--marked")) return
    this.pinned = false
    this.hidePopover()
  }

  showPopover(mark) {
    const messages = this.messagesFor(mark)
    if (this.activeMark && this.activeMark !== mark) {
      this.activeMark.removeAttribute("aria-expanded")
    }
    this.activeMark = mark
    mark.setAttribute("aria-expanded", "true")
    this.ensurePopover()
    this.renderPopover(messages)
    this.positionPopover(mark)
    this.popover.hidden = false
  }

  hidePopover() {
    if (!this.popover) return
    this.popover.hidden = true
    this.activeMark?.removeAttribute("aria-expanded")
    this.activeMark = null
  }

  messagesFor(mark) {
    const block = mark.matches?.("[data-rp-i]") ? mark : mark.closest?.("[data-rp-i]")
    const index = Number(block?.dataset?.rpI)
    const all = this.messagesByIndex.get(index) || []
    const quote = normalizeMarkText(mark.dataset?.rpQ || "")
    if (!quote) return all

    const filtered = all.filter((entry) => normalizeMarkText(entry.q) === quote)
    return filtered.length ? filtered : all
  }

  ensurePopover() {
    if (this.popover) return
    this.popover = document.createElement("div")
    this.popover.className = "paragraph-report-mark-popover"
    this.popover.setAttribute("role", "dialog")
    this.popover.setAttribute("aria-label", this.headingValue)
    this.popover.hidden = true
    this.popover.addEventListener("pointerleave", () => {
      if (!this.pinned) this.hidePopover()
    })
    document.body.appendChild(this.popover)
  }

  renderPopover(messages) {
    const empty = this.emptyValue
    const items = messages.length
      ? messages.map((entry) => {
          const user = escapeHtml(entry.u || "")
          const text = (entry.t || "").trim()
          const body = text
            ? `<span class="paragraph-report-mark-popover__text">${escapeHtml(text)}</span>`
            : `<span class="paragraph-report-mark-popover__text paragraph-report-mark-popover__empty">${escapeHtml(empty)}</span>`
          const line = user
            ? `<span class="paragraph-report-mark-popover__user">${user}:</span> ${body}`
            : body
          return `<li class="paragraph-report-mark-popover__item">${line}</li>`
        }).join("")
      : `<li class="paragraph-report-mark-popover__item"><span class="paragraph-report-mark-popover__text paragraph-report-mark-popover__empty">${escapeHtml(empty)}</span></li>`

    this.popover.innerHTML = `<ul class="paragraph-report-mark-popover__list">${items}</ul>`
  }

  positionPopover(mark) {
    const rect = mark.getBoundingClientRect()
    const panel = this.popover
    panel.style.left = "0px"
    panel.style.top = "0px"
    panel.hidden = false
    const width = panel.offsetWidth
    const height = panel.offsetHeight
    const margin = 8
    let left = rect.left + (window.scrollX || 0)
    let top = rect.bottom + (window.scrollY || 0) + margin
    const maxLeft = (window.scrollX || 0) + window.innerWidth - width - margin
    left = Math.max((window.scrollX || 0) + margin, Math.min(left, maxLeft))
    if (top + height > (window.scrollY || 0) + window.innerHeight - margin) {
      top = rect.top + (window.scrollY || 0) - height - margin
    }
    panel.style.left = `${Math.round(left)}px`
    panel.style.top = `${Math.round(top)}px`
  }
}

function uniqueQuotes(entries) {
  const seen = new Set()
  const quotes = []
  entries.forEach((entry) => {
    const quote = normalizeMarkText(entry.q)
    if (!quote || seen.has(quote)) return
    seen.add(quote)
    quotes.push(quote)
  })
  return quotes.length ? quotes : [""]
}

function normalizeEntries(entries) {
  if (!Array.isArray(entries)) return []
  return entries.map((entry) => {
    if (entry && typeof entry === "object") {
      return {
        u: String(entry.u || ""),
        t: String(entry.t || ""),
        q: String(entry.q || "")
      }
    }
    return { u: "", t: String(entry || ""), q: "" }
  })
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;")
}
