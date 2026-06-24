import { Controller } from "@hotwired/stimulus"
import { isAdblockLikely } from "adblock_detect"

const FILL_TIMEOUT_MS = { top: 3000, bottom: 5000 }
const SCRIPT_RETRY_MS = 300
const MAX_SCRIPT_RETRIES = 20

// Reserved-size chapter ad slot: house promo visible from first paint; swap to AdSense when filled.
export default class extends Controller {
  static targets = ["fallback"]
  static values = { live: Boolean, placement: { type: String, default: "top" }, fallback: Boolean }

  connect() {
    this.scriptRetries = 0
    this.boundReady = this.onReady.bind(this)
    this.boundTurboLoad = this.onReady.bind(this)
    document.addEventListener("baka:adsense-ready", this.boundReady)
    document.addEventListener("turbo:load", this.boundTurboLoad)

    if (!this.liveValue) return

    if (isAdblockLikely()) {
      this.showFallback()
      return
    }

    this.onReady()
  }

  disconnect() {
    document.removeEventListener("baka:adsense-ready", this.boundReady)
    document.removeEventListener("turbo:load", this.boundTurboLoad)
    this.clearRetry()
    this.stopWatching()
  }

  onReady() {
    if (!this.liveValue) return
    this.tryPush()
  }

  tryPush() {
    const ins = this.adElement()
    if (!ins || ins.dataset.adsensePushed === "true") return

    if (!window.adsbygoogle) {
      this.scriptRetries += 1
      if (this.scriptRetries >= MAX_SCRIPT_RETRIES) {
        this.showFallback()
        return
      }
      this.scheduleRetry()
      return
    }

    if (!this.slotIsRenderable(ins)) {
      this.scheduleRetry()
      return
    }

    try {
      ;(window.adsbygoogle = window.adsbygoogle || []).push({})
      ins.dataset.adsensePushed = "true"
      this.watchFill(ins)
    } catch (_error) {
      this.showFallback()
    }
  }

  slotIsRenderable(ins) {
    return ins.offsetParent !== null
  }

  scheduleRetry() {
    if (this.retryTimeout) return

    this.retryTimeout = window.setTimeout(() => {
      this.retryTimeout = null
      this.tryPush()
    }, SCRIPT_RETRY_MS)
  }

  clearRetry() {
    if (this.retryTimeout) {
      window.clearTimeout(this.retryTimeout)
      this.retryTimeout = null
    }
  }

  watchFill(ins) {
    this.stopWatching()

    const resolved = () => {
      if (this.isFilled(ins)) {
        this.showAdsenseFilled()
        return true
      }
      if (this.isUnfilled(ins)) {
        this.showFallback()
        return true
      }
      return false
    }

    if (resolved()) return

    this.fillObserver = new MutationObserver(() => {
      if (resolved()) this.stopWatching()
    })
    this.fillObserver.observe(ins, {
      attributes: true,
      attributeFilter: ["data-ad-status"],
      childList: true,
      subtree: true
    })

    this.fillTimeout = window.setTimeout(() => {
      this.stopWatching()
      if (!this.isFilled(ins)) this.showFallback()
    }, this.fillTimeoutMs())
  }

  fillTimeoutMs() {
    return FILL_TIMEOUT_MS[this.placementValue] || FILL_TIMEOUT_MS.top
  }

  isFilled(ins) {
    return ins.dataset.adStatus === "filled" || ins.querySelector("iframe") !== null
  }

  isUnfilled(ins) {
    return ins.dataset.adStatus === "unfilled"
  }

  adElement() {
    return this.element.querySelector("ins.adsbygoogle")
  }

  showAdsenseFilled() {
    this.element.classList.add("reader-ad-slot--adsense-filled")
  }

  showFallback() {
    this.clearRetry()
    this.stopWatching()
    this.element.classList.remove("reader-ad-slot--adsense-filled")
  }

  stopWatching() {
    if (this.fillObserver) {
      this.fillObserver.disconnect()
      this.fillObserver = null
    }
    if (this.fillTimeout) {
      window.clearTimeout(this.fillTimeout)
      this.fillTimeout = null
    }
  }
}
