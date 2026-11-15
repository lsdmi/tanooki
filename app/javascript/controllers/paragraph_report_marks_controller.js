import { Controller } from "@hotwired/stimulus"
import { markParagraphReportBlock } from "paragraph_report_marks"

// Paints open-report marks and shows reader messages on hover / click / keyboard.
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
      this.messagesByIndex.set(index, normalizeEntries(item.m))
      const block = this.content.querySelector(`[data-rp-i="${index}"]`)
      markParagraphReportBlock(block)
    })

    this.pinned = false
    this.activeBlock = null
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
    const existing = this.messagesByIndex.get(index) || []
    existing.push({
      u: String(event.detail?.user || "").trim(),
      t: String(event.detail?.message || "").trim()
    })
    this.messagesByIndex.set(index, existing)

    const block = this.content?.querySelector(`[data-rp-i="${index}"]`)
    markParagraphReportBlock(block)
  }

  onPointerOver(event) {
    if (this.pinned) return
    if (event.pointerType === "touch") return
    const block = event.target.closest?.(".paragraph-report--marked")
    if (!block || !this.content.contains(block)) return
    this.showPopover(block)
  }

  onPointerOut(event) {
    if (this.pinned) return
    if (event.pointerType === "touch") return
    const block = event.target.closest?.(".paragraph-report--marked")
    if (!block || !this.content.contains(block)) return
    const next = event.relatedTarget
    if (next && (block.contains(next) || this.popover?.contains(next))) return
    this.hidePopover()
  }

  onClick(event) {
    const block = event.target.closest?.(".paragraph-report--marked")
    if (!block || !this.content.contains(block)) return
    if (this.popover && this.activeBlock === block && this.pinned) {
      this.pinned = false
      this.hidePopover()
      return
    }
    this.pinned = true
    this.showPopover(block)
  }

  onKeydown(event) {
    if (event.key !== "Enter" && event.key !== " ") return
    const block = event.target.closest?.(".paragraph-report--marked")
    if (!block || !this.content.contains(block)) return
    event.preventDefault()
    this.pinned = true
    this.showPopover(block)
  }

  onDocPointer(event) {
    if (!this.popover) return
    if (this.popover.contains(event.target)) return
    if (event.target.closest?.(".paragraph-report--marked")) return
    this.pinned = false
    this.hidePopover()
  }

  showPopover(block) {
    const index = Number(block.dataset.rpI)
    const messages = this.messagesByIndex.get(index) || []
    if (this.activeBlock && this.activeBlock !== block) {
      this.activeBlock.removeAttribute("aria-expanded")
    }
    this.activeBlock = block
    block.setAttribute("aria-expanded", "true")
    this.ensurePopover()
    this.renderPopover(messages)
    this.positionPopover(block)
    this.popover.hidden = false
  }

  hidePopover() {
    if (!this.popover) return
    this.popover.hidden = true
    this.activeBlock?.removeAttribute("aria-expanded")
    this.activeBlock = null
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
            ? `<p class="paragraph-report-mark-popover__text">${escapeHtml(text)}</p>`
            : `<p class="paragraph-report-mark-popover__text paragraph-report-mark-popover__empty">${escapeHtml(empty)}</p>`
          return `<li class="paragraph-report-mark-popover__item"><span class="paragraph-report-mark-popover__user">${user}</span>${body}</li>`
        }).join("")
      : `<li class="paragraph-report-mark-popover__item"><p class="paragraph-report-mark-popover__text paragraph-report-mark-popover__empty">${escapeHtml(empty)}</p></li>`

    this.popover.innerHTML = `<ul class="paragraph-report-mark-popover__list">${items}</ul>`
  }

  positionPopover(block) {
    const rect = block.getBoundingClientRect()
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

function normalizeEntries(entries) {
  if (!Array.isArray(entries)) return []
  return entries.map((entry) => {
    if (entry && typeof entry === "object") {
      return { u: String(entry.u || ""), t: String(entry.t || "") }
    }
    return { u: "", t: String(entry || "") }
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
