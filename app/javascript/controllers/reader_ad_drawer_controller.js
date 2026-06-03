import { Controller } from "@hotwired/stimulus"

const DEFAULT_AUTO_CLOSE_MS = 5000

/** Full-screen ad grid drawer; auto-closes after a short delay. */
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
    this._onTurboLoad = () => this.close()

    document.addEventListener("turbo:load", this._onTurboLoad)

    if (this.shouldOpenValue) {
      requestAnimationFrame(() => this.open())
    }
  }

  disconnect() {
    document.removeEventListener("baka:adsense-ready", this.boundReady)
    document.removeEventListener("turbo:load", this._onTurboLoad)
    document.removeEventListener("keydown", this._onEscape)
    this.clearAutoClose()
    document.body.classList.remove("overflow-hidden")
  }

  onAdsenseReady() {
    if (this.isOpen()) this.pushAds()
  }

  open() {
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

    const template = this.countdownTemplateValue || "Auto-close in %{seconds} s"
    this.countdownTarget.textContent = template.replace("__SECONDS__", String(this.remainingSeconds))
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
