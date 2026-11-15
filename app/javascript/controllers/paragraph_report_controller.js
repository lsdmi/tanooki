import { Controller } from "@hotwired/stimulus"
import { fetchJson } from "translation_requests/http"
import { showErrorMessage, showSuccessMessage } from "flash_toast"
import { markParagraphReportBlock } from "paragraph_report_marks"

const LONG_PRESS_MS = 500
const MOVE_THRESHOLD_PX = 10
const QUOTE_LENGTH = 120
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

// Reader block error report: long-press on touch, context menu on desktop. Sheet lives outside the
// chapter body cache; listeners attach to #user-content on connect.
export default class extends Controller {
  static targets = ["backdrop", "panel", "quote", "message", "error", "submit", "form", "guest"]
  static values = {
    url: String,
    guest: Boolean,
    loginPath: String,
    success: String,
    error: String,
    reporterName: { type: String, default: "" },
    messageMax: { type: Number, default: 500 }
  }

  connect() {
    this.sheetOpen = false
    this.activeBlock = null
    this.payload = null
    this._onPointerDown = this.onPointerDown.bind(this)
    this._onContextMenu = this.onContextMenu.bind(this)
    this._onEscape = this.onEscape.bind(this)
    this._onPointerMove = this.onPointerMove.bind(this)
    this._onPointerUp = this.onPointerUp.bind(this)

    this.content = document.getElementById("user-content")
    if (!this.content) return

    this.content.addEventListener("pointerdown", this._onPointerDown)
    this.content.addEventListener("contextmenu", this._onContextMenu)
  }

  disconnect() {
    this.clearPress()
    this.close()
    this.content?.removeEventListener("pointerdown", this._onPointerDown)
    this.content?.removeEventListener("contextmenu", this._onContextMenu)
  }

  onPointerDown(event) {
    // Desktop uses contextmenu; long-press is for touch / pen so text selection stays intact.
    if (event.pointerType === "mouse") return
    if (this.locked()) return

    const block = event.target.closest?.("[data-rp-i]")
    if (!block || !this.content.contains(block)) return

    this.press = {
      block,
      x: event.clientX,
      y: event.clientY,
      pointerId: event.pointerId
    }
    this.longPressTimer = window.setTimeout(() => {
      this.longPressTimer = null
      if (!this.press) return
      if (this.hasTextSelection()) {
        this.clearPress()
        return
      }
      this.openFor(this.press.block)
      this.clearPress()
    }, LONG_PRESS_MS)

    window.addEventListener("pointermove", this._onPointerMove)
    window.addEventListener("pointerup", this._onPointerUp)
    window.addEventListener("pointercancel", this._onPointerUp)
  }

  onPointerMove(event) {
    if (!this.press) return
    const dx = event.clientX - this.press.x
    const dy = event.clientY - this.press.y
    if ((dx * dx) + (dy * dy) > MOVE_THRESHOLD_PX * MOVE_THRESHOLD_PX) this.clearPress()
  }

  onPointerUp() {
    this.clearPress()
  }

  onContextMenu(event) {
    if (this.locked()) return

    const block = event.target.closest?.("[data-rp-i]")
    if (!block || !this.content.contains(block)) return

    event.preventDefault()
    this.openFor(block)
  }

  openFor(block) {
    const full = this.normalizeText(block.textContent)
    const quote = full.slice(0, QUOTE_LENGTH)
    const digest = this.content.dataset.rpDigest || ""
    const blockIndex = Number(block.dataset.rpI)
    if (!quote || !digest || !Number.isInteger(blockIndex) || blockIndex < 0) return

    this.payload = { block_index: blockIndex, quote, digest }
    this.setActiveBlock(block)
    // Quote is capped at 120 chars (same anchor as reading resume); ellipsis is display-only.
    this.quoteTarget.textContent = full.length > QUOTE_LENGTH ? `${quote}…` : quote
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
        markParagraphReportBlock(reportedBlock)
        this.content?.dispatchEvent(new CustomEvent("paragraph-report:created", {
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

  normalizeText(text) {
    return (text || "").replace(/\s+/g, " ").trim()
  }

  normalizeQuote(text) {
    return this.normalizeText(text).slice(0, QUOTE_LENGTH)
  }

  locked() {
    return Boolean(this.content?.closest(".adult-content-gate--locked"))
  }

  hasTextSelection() {
    const selection = window.getSelection()
    return Boolean(selection && selection.toString().trim().length > 0)
  }

  clearPress() {
    if (this.longPressTimer) {
      window.clearTimeout(this.longPressTimer)
      this.longPressTimer = null
    }
    this.press = null
    window.removeEventListener("pointermove", this._onPointerMove)
    window.removeEventListener("pointerup", this._onPointerUp)
    window.removeEventListener("pointercancel", this._onPointerUp)
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
