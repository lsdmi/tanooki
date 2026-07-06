import { Controller } from "@hotwired/stimulus"
import { isAdblockLikely } from "adblock_detect"

const FILL_TIMEOUT_MS = { top: 8000, bottom: 12000 }
const SCRIPT_RETRY_MS = 300
const MAX_SCRIPT_RETRIES = 20
const PENDING_CLASS = "reader-ad-slot--pending"
const COLLAPSED_CLASS = "reader-ad-slot--collapsed"
const FILLED_CLASS = "reader-ad-slot--adsense-filled"

// In-chapter AdSense slot: layout-visible while pending; collapse only when unfilled or blocked.
export default class extends Controller {
  static values = {
    live: Boolean,
    placement: { type: String, default: "top" },
    navigationKey: { type: String, default: "" }
  }

  connect() {
    this.scriptRetries = 0
    this.seenTurboLoad = false
    this.previousNavigationKey = undefined
    this.boundReady = this.onReady.bind(this)
    this.boundTurboLoad = this.onTurboLoad.bind(this)
    document.addEventListener("baka:adsense-ready", this.boundReady)
    document.addEventListener("turbo:load", this.boundTurboLoad)

    if (!this.liveValue) return

    if (isAdblockLikely()) {
      this.hideSlot()
      return
    }

    this.prepareForFill()
    this.onReady()
  }

  disconnect() {
    document.removeEventListener("baka:adsense-ready", this.boundReady)
    document.removeEventListener("turbo:load", this.boundTurboLoad)
    this.clearRetry()
    this.stopWatching()
  }

  navigationKeyValueChanged() {
    if (!this.liveValue) return

    if (this.previousNavigationKey === undefined) {
      this.previousNavigationKey = this.navigationKeyValue
      return
    }

    if (this.previousNavigationKey === this.navigationKeyValue) return

    this.previousNavigationKey = this.navigationKeyValue
    this.resetForNavigation()
    if (isAdblockLikely()) {
      this.hideSlot()
      return
    }
    this.onReady()
  }

  onTurboLoad() {
    if (!this.liveValue) return

    if (!this.seenTurboLoad) {
      this.seenTurboLoad = true
      this.onReady()
      return
    }

    this.resetForNavigation()
    if (isAdblockLikely()) {
      this.hideSlot()
      return
    }
    this.onReady()
  }

  resetForNavigation() {
    this.clearRetry()
    this.stopWatching()
    this.scriptRetries = 0

    const ins = this.adElement()
    if (ins) {
      ins.querySelectorAll("iframe").forEach((node) => node.remove())
      delete ins.dataset.adsensePushed
      ins.removeAttribute("data-ad-status")
    }

    this.prepareForFill()
  }

  prepareForFill() {
    this.element.classList.remove(COLLAPSED_CLASS, FILLED_CLASS)
    this.element.classList.add(PENDING_CLASS)
    this.element.removeAttribute("hidden")
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

    this.prepareForFill()

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
    return ins.isConnected && ins.offsetParent !== null
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
    this.element.classList.remove(COLLAPSED_CLASS, PENDING_CLASS)
    this.element.classList.add(FILLED_CLASS)
    this.element.removeAttribute("hidden")
  }

  hideSlot() {
    this.clearRetry()
    this.stopWatching()
    this.element.classList.remove(PENDING_CLASS, FILLED_CLASS)
    this.element.classList.add(COLLAPSED_CLASS)
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
