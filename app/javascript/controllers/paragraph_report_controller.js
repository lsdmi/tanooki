import { Controller } from "@hotwired/stimulus"
import { fetchJson } from "translation_requests/http"
import { showErrorMessage, showSuccessMessage } from "flash_toast"
import { markParagraphReportQuote } from "paragraph_report_marks"

const QUOTE_LENGTH = 120
const CHIP_MARGIN = 8
const MOBILE_MQ = "(max-width: 639px)"
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
const MOBILE_TRIGGER_CLASS = [
  "inline-flex",
  "h-11",
  "w-11",
  "shrink-0",
  "items-center",
  "justify-center",
  "rounded-full",
  "border",
  "border-line/90",
  "bg-page/95",
  "text-fg",
  "shadow-md",
  "shadow-slate-900/10",
  "focus:outline-none",
  "focus-visible:ring-2",
  "focus-visible:ring-fg-subtle/80",
  "dark:shadow-black/40",
  "dark:focus-visible:ring-fg-brand/80"
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
const MOBILE_TRIGGER_SVG = `
<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
        d="M12 9v3.75m0 3.75h.01M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
</svg>
`.trim()

// Select text → desktop floating chip, or on phones a quiet icon beside «Зміст».
export default class extends Controller {
  static targets = ["backdrop", "panel", "quote", "message", "error", "submit"]
  static values = {
    url: String,
    guest: Boolean,
    success: String,
    error: String,
    chipLabel: { type: String, default: "Повідомити" },
    reporterName: { type: String, default: "" },
    messageMax: { type: Number, default: 500 }
  }

  connect() {
    this.sheetOpen = false
    this.activeBlock = null
    this.payload = null
    this.chip = null
    this.mobileTrigger = null
    this.mobileMq = window.matchMedia(MOBILE_MQ)
    this._onEscape = this.onEscape.bind(this)
    this._onSelectionChange = this.onSelectionChange.bind(this)
    this._onPointerUp = this.onPointerUp.bind(this)
    this._onScrollOrResize = this.onScrollOrResize.bind(this)
    this._onTriggerPointerDown = this.openFromTrigger.bind(this)
    this._onMobileMq = this.onMobileMq.bind(this)

    document.addEventListener("selectionchange", this._onSelectionChange)
    window.addEventListener("pointerup", this._onPointerUp)
    window.addEventListener("mouseup", this._onPointerUp)
    window.addEventListener("scroll", this._onScrollOrResize, true)
    window.addEventListener("resize", this._onScrollOrResize)
    this.mobileMq.addEventListener?.("change", this._onMobileMq)

    this.ensureContent()
  }

  disconnect() {
    this.destroyAffordances()
    this.close()
    document.removeEventListener("selectionchange", this._onSelectionChange)
    window.removeEventListener("pointerup", this._onPointerUp)
    window.removeEventListener("mouseup", this._onPointerUp)
    window.removeEventListener("scroll", this._onScrollOrResize, true)
    window.removeEventListener("resize", this._onScrollOrResize)
    this.mobileMq.removeEventListener?.("change", this._onMobileMq)
  }

  ensureContent() {
    this.content ||= document.getElementById("user-content")
    return this.content
  }

  mobileViewport() {
    return this.mobileMq.matches
  }

  onMobileMq() {
    this.hideAffordances()
    if (!this.sheetOpen && !this.locked()) this.syncAffordances()
  }

  onSelectionChange() {
    if (this.sheetOpen || this.locked()) {
      this.hideAffordances()
      return
    }
    window.requestAnimationFrame(() => this.syncAffordances())
  }

  onPointerUp() {
    if (this.sheetOpen || this.locked()) return
    window.requestAnimationFrame(() => this.syncAffordances())
  }

  onScrollOrResize() {
    if (this.sheetOpen) {
      this.hideAffordances()
      return
    }
    this.syncAffordances()
  }

  openFromTrigger(event) {
    event.preventDefault()
    event.stopPropagation()
    const found = this.selectionInBlock()
    if (!found) {
      this.hideAffordances()
      return
    }
    this.hideAffordances()
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
    this.sheetOpen = false
    this.clearInlineError()
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
        const reportedQuote = this.payload?.quote
        markParagraphReportQuote(reportedBlock, reportedQuote)
        this.ensureContent()?.dispatchEvent(new CustomEvent("paragraph-report:created", {
          detail: {
            blockIndex: this.payload?.block_index,
            message: reportedMessage,
            quote: reportedQuote,
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

  syncAffordances() {
    const found = this.selectionInBlock()
    if (!found) {
      this.hideAffordances()
      return
    }

    if (this.mobileViewport()) {
      this.hideChip()
      this.showMobileTrigger()
      return
    }

    this.hideMobileTrigger()
    this.syncChip()
  }

  syncChip() {
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
    chip.addEventListener("pointerdown", this._onTriggerPointerDown)
    document.body.appendChild(chip)
    this.chip = chip
    return chip
  }

  ensureMobileTrigger() {
    if (this.mobileTrigger) return this.mobileTrigger

    const button = document.createElement("button")
    button.type = "button"
    button.className = `${MOBILE_TRIGGER_CLASS} fixed z-40 sm:hidden`
    button.hidden = true
    button.setAttribute("data-paragraph-report-mobile-trigger", "")
    button.setAttribute("aria-label", this.chipLabelValue)
    button.innerHTML = MOBILE_TRIGGER_SVG
    button.addEventListener("pointerdown", this._onTriggerPointerDown)
    document.body.appendChild(button)
    this.mobileTrigger = button
    return button
  }

  showMobileTrigger() {
    const button = this.ensureMobileTrigger()
    this.positionMobileTrigger()
    button.hidden = false
  }

  // Sit just right of «Зміст» when that dock is on screen; otherwise bottom-left alone.
  positionMobileTrigger() {
    const button = this.mobileTrigger
    if (!button) return

    const dock = document.querySelector("[data-reader-mobile-dock]")
    if (dock && !dock.hidden) {
      const rect = dock.getBoundingClientRect()
      button.style.left = `${Math.round(rect.right + 8)}px`
      button.style.bottom = `${Math.round(window.innerHeight - rect.bottom)}px`
      button.style.top = "auto"
      return
    }

    button.style.left = "1rem"
    button.style.bottom = "1rem"
    button.style.top = "auto"
  }

  hideChip() {
    if (!this.chip) return
    this.chip.hidden = true
  }

  hideMobileTrigger() {
    if (!this.mobileTrigger) return
    this.mobileTrigger.hidden = true
  }

  hideAffordances() {
    this.hideChip()
    this.hideMobileTrigger()
  }

  destroyAffordances() {
    this.destroyChip()
    this.destroyMobileTrigger()
  }

  destroyChip() {
    if (!this.chip) return
    this.chip.removeEventListener("pointerdown", this._onTriggerPointerDown)
    this.chip.remove()
    this.chip = null
  }

  destroyMobileTrigger() {
    if (!this.mobileTrigger) return
    this.mobileTrigger.removeEventListener("pointerdown", this._onTriggerPointerDown)
    this.mobileTrigger.remove()
    this.mobileTrigger = null
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
