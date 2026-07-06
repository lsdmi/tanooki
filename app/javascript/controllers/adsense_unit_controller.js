import { Controller } from "@hotwired/stimulus"
import { isAdblockLikely } from "adblock_detect"

const FILL_TIMEOUT_MS = { top: 3000, bottom: 5000 }
const SCRIPT_RETRY_MS = 300
const MAX_SCRIPT_RETRIES = 20
const COLLAPSED_CLASS = "reader-ad-slot--collapsed"
const FILLED_CLASS = "reader-ad-slot--adsense-filled"

// In-chapter AdSense slot: collapsed until filled; removed from layout when unfilled or blocked.
export default class extends Controller {
  static values = { live: Boolean, placement: { type: String, default: "top" } }

  connect() {
    this.scriptRetries = 0
    this.boundReady = this.onReady.bind(this)
    this.boundTurboLoad = this.onReady.bind(this)
    document.addEventListener("baka:adsense-ready", this.boundReady)
    document.addEventListener("turbo:load", this.boundTurboLoad)

    if (!this.liveValue) return

    if (isAdblockLikely()) {
      this.hideSlot()
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
        this.hideSlot()
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
      this.hideSlot()
    }
  }

  slotIsRenderable(ins) {
    return ins.isConnected
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
        this.showSlot()
        return true
      }
      if (this.isUnfilled(ins)) {
        this.hideSlot()
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
      if (!this.isFilled(ins)) this.hideSlot()
    }, this.fillTimeoutMs())
  }

  fillTimeoutMs() {
    return FILL_TIMEOUT_MS[this.placementValue] || FILL_TIMEOUT_MS.top
  }

  isFilled(ins) {
    const status = ins.dataset.adStatus
    if (status === "filled") return true
    if (ins.querySelector("iframe")) return true
    return false
  }

  isUnfilled(ins) {
    const status = ins.dataset.adStatus
    if (status === "unfilled") return true
    if (status === "unfilled-optimized" && !ins.querySelector("iframe")) return true
    return false
  }

  adElement() {
    return this.element.querySelector("ins.adsbygoogle")
  }

  showSlot() {
    this.element.classList.remove(COLLAPSED_CLASS)
    this.element.classList.add(FILLED_CLASS)
    this.element.removeAttribute("hidden")
  }

  hideSlot() {
    this.clearRetry()
    this.stopWatching()
    this.element.classList.add(COLLAPSED_CLASS)
    this.element.classList.remove(FILLED_CLASS)
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
