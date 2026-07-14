import { Controller } from "@hotwired/stimulus"
import { isAdblockLikely } from "adblock_detect"

const FILL_TIMEOUT_MS = { top: 2500, bottom: 4000, home_banner: 4000 }
const SCRIPT_RETRY_MS = 250
const MAX_SCRIPT_RETRIES = 10
const PENDING_CLASS = "reader-ad-slot--pending"
const MEASURING_CLASS = "reader-ad-slot--measuring"
const COLLAPSED_CLASS = "reader-ad-slot--collapsed"
const FILLED_CLASS = "reader-ad-slot--adsense-filled"

// In-chapter AdSense: no layout until push; collapse without scroll jump when unfilled or blocked.
// Google allows one push() per <ins> — replace the node on each Turbo visit before re-pushing.
export default class extends Controller {
  static values = {
    live: Boolean,
    placement: { type: String, default: "top" },
    navigationKey: { type: String, default: "" }
  }

  connect() {
    this.scriptRetries = 0
    this.visitGeneration = 0
    this.previousNavigationKey = undefined
    this.boundReady = this.onReady.bind(this)
    this.boundVisit = this.onVisit.bind(this)
    document.addEventListener("baka:adsense-ready", this.boundReady)
    document.addEventListener("baka:adsense-visit", this.boundVisit)

    if (!this.liveValue) return

    if (isAdblockLikely()) {
      this.hideSlot()
      return
    }

    this.scheduleInitialPush()
  }

  scheduleInitialPush() {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => this.onReady())
    })
  }

  disconnect() {
    document.removeEventListener("baka:adsense-ready", this.boundReady)
    document.removeEventListener("baka:adsense-visit", this.boundVisit)
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
    this.beginFillAttempt()
  }

  onVisit() {
    if (!this.liveValue) return
    this.beginFillAttempt()
  }

  beginFillAttempt() {
    if (isAdblockLikely()) {
      this.hideSlot()
      return
    }

    this.resetForNavigation()
    this.onReady()
  }

  resetForNavigation() {
    this.visitGeneration += 1
    this.clearRetry()
    this.stopWatching()
    this.scriptRetries = 0
    this.clearMeasuring()
    this.replaceAdElement()
  }

  replaceAdElement() {
    const frame = this.element.querySelector(".reader-ad-slot__frame")
    const ins = this.adElement()
    if (!frame || !ins) return null

    const fresh = document.createElement("ins")
    fresh.className = "adsbygoogle reader-ad-slot__adsense"
    fresh.style.display = "block"
    fresh.setAttribute("data-ad-client", ins.dataset.adClient)
    fresh.setAttribute("data-ad-slot", ins.dataset.adSlot)
    fresh.setAttribute("data-ad-format", ins.getAttribute("data-ad-format") || "auto")
    fresh.setAttribute("data-full-width-responsive", ins.getAttribute("data-full-width-responsive") || "true")
    ins.replaceWith(fresh)
    return fresh
  }

  beginMeasuring() {
    this.element.classList.remove(COLLAPSED_CLASS, FILLED_CLASS)
    this.element.classList.add(PENDING_CLASS, MEASURING_CLASS)
    this.element.removeAttribute("hidden")
  }

  clearMeasuring() {
    if (!this.element.classList.contains(MEASURING_CLASS)) {
      this.element.classList.remove(PENDING_CLASS, MEASURING_CLASS)
      return
    }

    this.preserveScroll(() => {
      this.element.classList.remove(PENDING_CLASS, MEASURING_CLASS)
    })
  }

  onReady() {
    if (!this.liveValue) return
    this.tryPush()
  }

  tryPush() {
    const generation = this.visitGeneration
    const ins = this.adElement()
    if (!ins || ins.dataset.adsensePushed === "true") return

    if (isAdblockLikely()) {
      this.hideSlot()
      return
    }

    if (!window.adsbygoogle) {
      this.scriptRetries += 1
      if (this.scriptRetries >= MAX_SCRIPT_RETRIES) {
        this.hideSlot()
        return
      }
      this.scheduleRetry(generation)
      return
    }

    this.beginMeasuring()

    if (!this.slotIsRenderable(ins)) {
      this.scheduleRetry(generation)
      return
    }

    try {
      ;(window.adsbygoogle = window.adsbygoogle || []).push({})
      ins.dataset.adsensePushed = "true"
      this.watchFill(ins, generation)
    } catch (_error) {
      this.hideSlot()
    }
  }

  slotIsRenderable(ins) {
    const frame = ins.closest(".reader-ad-slot__frame")
    const target = frame || ins
    return target.isConnected && target.offsetParent !== null
  }

  scheduleRetry(generation) {
    if (this.retryTimeout) return

    this.retryTimeout = window.setTimeout(() => {
      this.retryTimeout = null
      if (generation !== this.visitGeneration) return
      this.tryPush()
    }, SCRIPT_RETRY_MS)
  }

  clearRetry() {
    if (this.retryTimeout) {
      window.clearTimeout(this.retryTimeout)
      this.retryTimeout = null
    }
  }

  watchFill(ins, generation) {
    this.stopWatching()

    const resolved = () => {
      if (generation !== this.visitGeneration) return true

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
      if (generation !== this.visitGeneration) return
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
    this.element.classList.remove(COLLAPSED_CLASS, PENDING_CLASS, MEASURING_CLASS)
    this.element.classList.add(FILLED_CLASS)
    this.element.removeAttribute("hidden")
  }

  hideSlot() {
    this.preserveScroll(() => {
      this.clearRetry()
      this.stopWatching()
      this.clearMeasuring()
      this.element.classList.remove(FILLED_CLASS)
      this.element.classList.add(COLLAPSED_CLASS)
    })
  }

  preserveScroll(callback) {
    const scrollX = window.scrollX
    const scrollY = window.scrollY
    callback()
    requestAnimationFrame(() => {
      window.scrollTo(scrollX, scrollY)
    })
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
