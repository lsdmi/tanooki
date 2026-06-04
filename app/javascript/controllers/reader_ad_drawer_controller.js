import { Controller } from "@hotwired/stimulus"
import { isAdblockLikely } from "adblock_detect"

const DEFAULT_AUTO_CLOSE_MS = 10_000
const ADSENSE_WAIT_MS = 2_000

/** Full-screen ad grid drawer; auto-closes after a short delay. Skipped when adblock is detected. */
export default class extends Controller {
  static targets = ["backdrop", "panel", "countdown"]
  static values = {
    shouldOpen: Boolean,
    autoCloseMs: { type: Number, default: DEFAULT_AUTO_CLOSE_MS },
    countdownTemplate: String
  }

  connect() {
    this.boundReady = this.onAdsenseReady.bind(this)
    document.addEventListener("baka:adsense-ready", this.boundReady)
    this._onEscape = this._onEscape.bind(this)
    this._onTurboLoad = this._onTurboLoad.bind(this)

    document.addEventListener("turbo:load", this._onTurboLoad)

    if (this.shouldOpenValue) this.scheduleOpen()
  }

  disconnect() {
    document.removeEventListener("baka:adsense-ready", this.boundReady)
    document.removeEventListener("turbo:load", this._onTurboLoad)
    document.removeEventListener("keydown", this._onEscape)
    this.clearAdsenseWait()
    this.close()
  }

  _onTurboLoad() {
    if (!this.shouldOpenValue) this.close()
  }

  onAdsenseReady() {
    if (this._adsenseWaitTimeout) {
      this.clearAdsenseWait()
      if (!isAdblockLikely()) this.open()
      return
    }

    if (this.isOpen()) this.pushAds()
  }

  scheduleOpen() {
    if (isAdblockLikely()) return

    if (window.adsbygoogle) {
      requestAnimationFrame(() => this.open())
      return
    }

    this._adsenseWaitTimeout = window.setTimeout(() => {
      this._adsenseWaitTimeout = null
      if (!isAdblockLikely() && window.adsbygoogle) this.open()
    }, ADSENSE_WAIT_MS)
  }

  clearAdsenseWait() {
    if (this._adsenseWaitTimeout) {
      window.clearTimeout(this._adsenseWaitTimeout)
      this._adsenseWaitTimeout = null
    }
  }

  open() {
    if (isAdblockLikely()) return
    if (!this.hasBackdropTarget || !this.hasPanelTarget) return

    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.add("opacity-100", "pointer-events-auto")
    this.backdropTarget.setAttribute("aria-hidden", "false")

    this.panelTarget.classList.remove("opacity-0", "pointer-events-none", "invisible")
    this.panelTarget.classList.add("opacity-100", "pointer-events-auto", "visible")

    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this._onEscape)

    this.pushAds()
    this.startAutoClose()
  }

  close() {
    if (!this.hasBackdropTarget || !this.hasPanelTarget) return

    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.remove("opacity-100", "pointer-events-auto")
    this.backdropTarget.setAttribute("aria-hidden", "true")

    this.panelTarget.classList.add("opacity-0", "pointer-events-none", "invisible")
    this.panelTarget.classList.remove("opacity-100", "pointer-events-auto", "visible")

    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this._onEscape)
    this.clearAutoClose()
  }

  isOpen() {
    return this.hasPanelTarget && this.panelTarget.classList.contains("visible")
  }

  pushAds() {
    if (!window.adsbygoogle) return

    this.element.querySelectorAll("ins.adsbygoogle").forEach((ins) => {
      if (ins.dataset.adsensePushed === "true") return
      if (ins.offsetParent === null) return

      try {
        ;(window.adsbygoogle = window.adsbygoogle || []).push({})
        ins.dataset.adsensePushed = "true"
      } catch (_error) {
        /* ignore fill errors */
      }
    })
  }

  startAutoClose() {
    this.clearAutoClose()
    const ms = this.autoCloseMsValue
    if (ms <= 0) return

    this.remainingSeconds = Math.max(1, Math.ceil(ms / 1000))
    this.updateCountdownLabel()

    this.countdownInterval = window.setInterval(() => {
      this.remainingSeconds -= 1
      this.updateCountdownLabel()
      if (this.remainingSeconds <= 0) this.close()
    }, 1000)
  }

  updateCountdownLabel() {
    if (!this.hasCountdownTarget) return

    const template =
      this.countdownTemplateValue || "Автозакриття через __SECONDS__ с"
    const seconds = String(this.remainingSeconds)
    this.countdownTarget.textContent = template
      .replaceAll("__SECONDS__", seconds)
      .replaceAll("%{seconds}", seconds)
  }

  clearAutoClose() {
    if (this.countdownInterval) {
      window.clearInterval(this.countdownInterval)
      this.countdownInterval = null
    }
  }

  _onEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
