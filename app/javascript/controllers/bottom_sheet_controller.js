import { Controller } from "@hotwired/stimulus"

const DESKTOP_QUERY = "(min-width: 768px)"
const SWIPE_CLOSE_PX = 64
const CLOSE_MS = 200
const FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'

/** Ui::BottomSheetComponent: modal bottom sheet below md, dropdown anchored to the trigger from md up. */
export default class extends Controller {
  static targets = ["trigger", "scrim", "panel"]

  connect() {
    this.opened = false
    this.media = window.matchMedia(DESKTOP_QUERY)
    this.onDocumentPointerDown = this.onDocumentPointerDown.bind(this)
    this.onMediaChange = () => this.close({ restoreFocus: false, immediate: true })
    this.onBeforeCache = () => this.close({ restoreFocus: false, immediate: true })
    this.media.addEventListener("change", this.onMediaChange)
    document.addEventListener("turbo:before-cache", this.onBeforeCache)

    const button = this.triggerButton
    button?.setAttribute("aria-haspopup", "dialog")
    button?.setAttribute("aria-controls", this.panelTarget.id)
    button?.setAttribute("aria-expanded", "false")
  }

  disconnect() {
    this.media.removeEventListener("change", this.onMediaChange)
    document.removeEventListener("turbo:before-cache", this.onBeforeCache)
    this.close({ restoreFocus: false, immediate: true })
  }

  get triggerButton() {
    if (!this.hasTriggerTarget) return null
    return this.triggerTarget.querySelector(FOCUSABLE)
  }

  toggle(event) {
    this.opened ? this.close() : this.open(event)
  }

  open() {
    if (this.opened) return

    clearTimeout(this.hideTimer)
    this.opened = true
    this.sheet = !this.media.matches
    this.opener = this.triggerButton || document.activeElement

    this.panelTarget.hidden = false
    this.panelTarget.setAttribute("aria-modal", String(this.sheet))
    if (this.sheet) {
      this.scrimTarget.hidden = false
      raise(this.scrimTarget)
      raise(this.panelTarget)
      document.body.classList.add("overflow-hidden")
      requestAnimationFrame(() => {
        this.scrimTarget.classList.replace("opacity-0", "opacity-100")
        this.panelTarget.classList.remove("translate-y-full")
      })
    }

    this.triggerButton?.setAttribute("aria-expanded", "true")
    const firstItem = this.focusables[0] || this.panelTarget
    firstItem.focus({ preventScroll: true })
    setTimeout(() => document.addEventListener("pointerdown", this.onDocumentPointerDown, true))
  }

  close({ restoreFocus = true, immediate = false } = {}) {
    if (!this.opened) return

    this.opened = false
    document.removeEventListener("pointerdown", this.onDocumentPointerDown, true)
    this.triggerButton?.setAttribute("aria-expanded", "false")
    const focusInside = this.panelTarget.contains(document.activeElement)

    const hide = () => {
      lower(this.panelTarget)
      lower(this.scrimTarget)
      this.panelTarget.hidden = true
      this.scrimTarget.hidden = true
    }
    if (this.sheet) {
      document.body.classList.remove("overflow-hidden")
      this.scrimTarget.classList.replace("opacity-100", "opacity-0")
      this.panelTarget.classList.add("translate-y-full")
      this.panelTarget.style.translate = ""
      this.panelTarget.style.transition = ""
    }
    if (this.sheet && !immediate) {
      this.hideTimer = setTimeout(hide, CLOSE_MS)
    } else {
      hide()
    }

    if (restoreFocus && (focusInside || document.activeElement === document.body)) {
      this.opener?.focus({ preventScroll: true })
    }
    this.opener = null
    this.dispatch("closed")
  }

  select(event) {
    if (event.target.closest("a[href], button")) this.close()
  }

  keydown(event) {
    if (!this.opened) return

    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    } else if (event.key === "Tab" && this.sheet) {
      this.trapFocus(event)
    }
  }

  focusOut(event) {
    if (!this.opened || this.sheet) return
    if (event.relatedTarget && !this.element.contains(event.relatedTarget)) this.close({ restoreFocus: false })
  }

  dragStart(event) {
    if (!this.sheet || event.button > 0) return

    const startY = event.clientY
    let delta = 0
    this.panelTarget.style.transition = "none"

    const move = (moveEvent) => {
      delta = Math.max(0, moveEvent.clientY - startY)
      this.panelTarget.style.translate = `0 ${delta}px`
    }
    const end = () => {
      window.removeEventListener("pointermove", move)
      window.removeEventListener("pointerup", end)
      window.removeEventListener("pointercancel", end)
      this.panelTarget.style.transition = ""
      if (delta > SWIPE_CLOSE_PX) {
        this.close()
      } else {
        this.panelTarget.style.translate = ""
      }
    }
    window.addEventListener("pointermove", move)
    window.addEventListener("pointerup", end)
    window.addEventListener("pointercancel", end)
  }

  onDocumentPointerDown(event) {
    if (!this.element.contains(event.target)) this.close({ restoreFocus: false })
  }

  trapFocus(event) {
    const items = this.focusables
    if (items.length === 0) {
      event.preventDefault()
      return
    }

    const first = items[0]
    const last = items[items.length - 1]
    const active = document.activeElement
    if (event.shiftKey && (active === first || active === this.panelTarget)) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && active === last) {
      event.preventDefault()
      first.focus()
    }
  }

  get focusables() {
    return [...this.panelTarget.querySelectorAll(FOCUSABLE)]
  }
}

// A sheet goes to the top layer: the menu can sit inside a z-indexed stacking context (the fiction page main),
// and sticky tabs or the chat button would cover it there.
function raise(element) {
  if (!element.showPopover) return

  element.popover = "manual"
  element.showPopover()
}

function lower(element) {
  if (!element.hasAttribute("popover")) return

  if (element.matches(":popover-open")) element.hidePopover()
  element.removeAttribute("popover")
}
