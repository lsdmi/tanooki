import { Controller } from "@hotwired/stimulus"
import { fetchJson } from "translation_requests/http"
import { showErrorMessage, showSuccessMessage } from "flash_toast"
import { markParagraphReportBlock } from "paragraph_report_marks"

const QUOTE_LENGTH = 120
const CHIP_MARGIN = 8
const CHIP_CLASS = [
  "fixed",
  "z-[70]",
  "max-w-[calc(100vw-1rem)]",
  "cursor-pointer",
  "rounded-lg",
  "border",
  "border-line-strong",
  "bg-main",
  "px-3.5",
  "py-2",
  "text-sm",
  "font-semibold",
  "leading-tight",
  "text-fg",
  "shadow-lg",
  "shadow-stone-900/10",
  "transition-colors",
  "hover:bg-surface",
  "focus:outline-none",
  "focus-visible:ring-2",
  "focus-visible:ring-brand/55",
  "focus-visible:ring-offset-2",
  "focus-visible:ring-offset-main",
  "dark:shadow-black/30"
].join(" ")
const ACTIVE_CLASSES = [
  "rounded",
  "outline",
  "outline-2",
  "outline-offset-2",
  "outline-brand/55",
  "bg-brand/8"
]
const PANEL_HIDDEN_CLASS = "translate-y-full"
const PANEL_SHOWN_CLASS = "translate-y-0"

// Desktop: context menu on a reader block. Any pointer: select text → floating «Повідомити» chip
// (ported to document.body so reader stacking / main z-10 cannot hide it).
export default class extends Controller {
  static targets = ["backdrop", "panel", "quote", "message", "error", "submit", "form", "guest"]
  static values = {
    url: String,
    guest: Boolean,
    loginPath: String,
    success: String,
    error: String,
    copied: String,
    copyFailed: String,
    chipLabel: { type: String, default: "Повідомити" },
    reporterName: { type: String, default: "" },
    messageMax: { type: Number, default: 500 }
  }

  connect() {
    this.sheetOpen = false
    this.activeBlock = null
    this.payload = null
    this.copyText = ""
    this.chip = null
    this._onContextMenu = this.onContextMenu.bind(this)
    this._onEscape = this.onEscape.bind(this)
    this._onSelectionChange = this.onSelectionChange.bind(this)
    this._onPointerUp = this.onPointerUp.bind(this)
    this._onScrollOrResize = this.onScrollOrResize.bind(this)
    this._onChipPointerDown = this.openFromChip.bind(this)

    document.addEventListener("contextmenu", this._onContextMenu)
    document.addEventListener("selectionchange", this._onSelectionChange)
    window.addEventListener("pointerup", this._onPointerUp)
    window.addEventListener("mouseup", this._onPointerUp)
    window.addEventListener("scroll", this._onScrollOrResize, true)
    window.addEventListener("resize", this._onScrollOrResize)

    this.ensureContent()
  }

  disconnect() {
    this.destroyChip()
    this.close()
    document.removeEventListener("contextmenu", this._onContextMenu)
    document.removeEventListener("selectionchange", this._onSelectionChange)
    window.removeEventListener("pointerup", this._onPointerUp)
    window.removeEventListener("mouseup", this._onPointerUp)
    window.removeEventListener("scroll", this._onScrollOrResize, true)
    window.removeEventListener("resize", this._onScrollOrResize)
  }

  ensureContent() {
    this.content ||= document.getElementById("user-content")
    return this.content
  }

  onContextMenu(event) {
    const content = this.ensureContent()
    if (!content || this.locked()) return

    const block = event.target.closest?.("[data-rp-i]")
    if (!block || !content.contains(block)) return

    event.preventDefault()
    this.hideChip()
    this.openFor(block)
  }

  onSelectionChange() {
    if (this.sheetOpen || this.locked()) {
      this.hideChip()
      return
    }
    window.requestAnimationFrame(() => this.syncChip())
  }

  onPointerUp() {
    if (this.sheetOpen || this.locked()) return
    window.requestAnimationFrame(() => this.syncChip())
  }

  onScrollOrResize() {
    if (this.sheetOpen) {
      this.hideChip()
      return
    }
    this.syncChip()
  }

  openFromChip(event) {
    event.preventDefault()
    event.stopPropagation()
    const found = this.selectionInBlock()
    if (!found) {
      this.hideChip()
      return
    }
    this.hideChip()
    this.openFor(found.block, found.text)
  }

  openFor(block, selectedText = null) {
    const content = this.ensureContent()
    if (!content) return

    const full = this.normalizeText(block.textContent)
    const selected = this.normalizeText(selectedText)
    const quoteSource = selected || full
    const quote = quoteSource.slice(0, QUOTE_LENGTH)
    const digest = content.dataset.rpDigest || ""
    const blockIndex = Number(block.dataset.rpI)
    if (!quote || !digest || !Number.isInteger(blockIndex) || blockIndex < 0) return

    this.clearNativeSelection()
    this.copyText = full
    this.payload = { block_index: blockIndex, quote, digest }
    this.setActiveBlock(block)
    this.quoteTarget.textContent = quoteSource.length > QUOTE_LENGTH ? `${quote}…` : quote
    this.clearInlineError()
    if (this.hasMessageTarget) this.messageTarget.value = ""

    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.add("opacity-100", "pointer-events-auto")
    this.backdropTarget.setAttribute("aria-hidden", "false")

    this.panelTarget.classList.remove(PANEL_HIDDEN_CLASS)
    this.panelTarget.classList.add(PANEL_SHOWN_CLASS)
    this.panelTarget.setAttribute("aria-hidden", "false")

    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this._onEscape)
    this.sheetOpen = true

    requestAnimationFrame(() => this.focusInitialControl())
  }

  close(event) {
    event?.preventDefault()
    if (!this.hasBackdropTarget || !this.hasPanelTarget) return

    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.remove("opacity-100", "pointer-events-auto")
    this.backdropTarget.setAttribute("aria-hidden", "true")

    this.panelTarget.classList.add(PANEL_HIDDEN_CLASS)
    this.panelTarget.classList.remove(PANEL_SHOWN_CLASS)
    this.panelTarget.setAttribute("aria-hidden", "true")

    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this._onEscape)
    this.setActiveBlock(null)
    this.payload = null
    this.copyText = ""
    this.sheetOpen = false
    this.clearInlineError()
  }

  async copy(event) {
    event.preventDefault()
    const text = this.copyText
    if (!text) return

    try {
      await this.writeClipboard(text)
      this.close()
      showSuccessMessage(this.copiedValue)
    } catch {
      showErrorMessage(this.copyFailedValue)
    }
  }

  submit(event) {
    event.preventDefault()
    if (this.guestValue || !this.payload || !this.hasSubmitTarget) return
    if (this.submitTarget.disabled) return

    const message = this.hasMessageTarget ? this.messageTarget.value.trim() : ""
    if (message.length > this.messageMaxValue) {
      this.showInlineError(this.errorValue)
      return
    }

    const body = { ...this.payload }
    if (message) body.message = message

    this.submitTarget.disabled = true
    this.clearInlineError()

    fetchJson(this.urlValue, { method: "POST", body })
      .then(({ response, data }) => {
        if (!response.ok || data.error) {
          this.showInlineError(data.error || this.errorValue)
          return
        }

        const reportedBlock = this.activeBlock
        const reportedMessage = message
        markParagraphReportBlock(reportedBlock)
        this.ensureContent()?.dispatchEvent(new CustomEvent("paragraph-report:created", {
          detail: {
            blockIndex: this.payload?.block_index,
            message: reportedMessage,
            user: this.reporterNameValue
          }
        }))
        this.close()
        showSuccessMessage(this.successValue)
      })
      .catch(() => {
        this.showInlineError(this.errorValue)
        showErrorMessage(this.errorValue)
      })
      .finally(() => {
        if (this.hasSubmitTarget) this.submitTarget.disabled = false
      })
  }

  onEscape(event) {
    if (event.key === "Escape" && this.sheetOpen) this.close()
  }

  syncChip() {
    const found = this.selectionInBlock()
    if (!found) {
      this.hideChip()
      return
    }

    const selection = window.getSelection()
    const range = selection?.getRangeAt(0)
    if (!range) {
      this.hideChip()
      return
    }

    let rect = range.getBoundingClientRect()
    if (!rect.width && !rect.height) {
      rect = range.getClientRects()[0]
    }
    if (!rect || (!rect.width && !rect.height)) {
      this.hideChip()
      return
    }

    const chip = this.ensureChip()
    chip.hidden = false
    const width = chip.offsetWidth
    const height = chip.offsetHeight
    let left = rect.left + (rect.width / 2) - (width / 2)
    let top = rect.top - height - CHIP_MARGIN
    if (top < CHIP_MARGIN) top = rect.bottom + CHIP_MARGIN
    left = Math.max(CHIP_MARGIN, Math.min(left, window.innerWidth - width - CHIP_MARGIN))
    top = Math.max(CHIP_MARGIN, Math.min(top, window.innerHeight - height - CHIP_MARGIN))
    chip.style.left = `${Math.round(left)}px`
    chip.style.top = `${Math.round(top)}px`
  }

  ensureChip() {
    if (this.chip) return this.chip

    const chip = document.createElement("button")
    chip.type = "button"
    chip.className = CHIP_CLASS
    chip.textContent = this.chipLabelValue
    chip.hidden = true
    chip.setAttribute("data-paragraph-report-chip", "")
    chip.addEventListener("pointerdown", this._onChipPointerDown)
    document.body.appendChild(chip)
    this.chip = chip
    return chip
  }

  hideChip() {
    if (!this.chip) return
    this.chip.hidden = true
  }

  destroyChip() {
    if (!this.chip) return
    this.chip.removeEventListener("pointerdown", this._onChipPointerDown)
    this.chip.remove()
    this.chip = null
  }

  selectionInBlock() {
    const content = this.ensureContent()
    if (!content) return null

    const selection = window.getSelection()
    if (!selection || selection.isCollapsed || !selection.rangeCount) return null

    const text = this.normalizeText(selection.toString())
    if (!text) return null

    const node = selection.anchorNode
    const el = node?.nodeType === Node.ELEMENT_NODE ? node : node?.parentElement
    const block = el?.closest?.("[data-rp-i]")
    if (!block || !content.contains(block)) return null

    return { block, text }
  }

  normalizeText(text) {
    return (text || "").replace(/\s+/g, " ").trim()
  }

  locked() {
    return Boolean(this.ensureContent()?.closest(".adult-content-gate--locked"))
  }

  clearNativeSelection() {
    const selection = window.getSelection()
    if (selection && selection.rangeCount > 0) selection.removeAllRanges()
  }

  async writeClipboard(text) {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text)
      return
    }

    const field = document.createElement("textarea")
    field.value = text
    field.setAttribute("readonly", "")
    field.style.position = "fixed"
    field.style.top = "-9999px"
    document.body.appendChild(field)
    field.select()
    const ok = document.execCommand("copy")
    field.remove()
    if (!ok) throw new Error("copy failed")
  }

  setActiveBlock(block) {
    this.activeBlock?.classList.remove(...ACTIVE_CLASSES)
    this.activeBlock = block
    this.activeBlock?.classList.add(...ACTIVE_CLASSES)
  }

  focusInitialControl() {
    if (this.hasMessageTarget) {
      this.messageTarget.focus()
      return
    }
    this.panelTarget.querySelector("a, button")?.focus()
  }

  showInlineError(message) {
    if (!this.hasErrorTarget) {
      showErrorMessage(message)
      return
    }
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  clearInlineError() {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }
}
