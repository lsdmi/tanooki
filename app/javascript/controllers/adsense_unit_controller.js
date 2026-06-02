import { Controller } from "@hotwired/stimulus"

const FILL_TIMEOUT_MS = 5000

// Pushes AdSense for one unit; shows the slot only when an ad fills, hides on unfilled/error.
export default class extends Controller {
  static values = { live: Boolean, placement: String }

  connect() {
    this.boundReady = this.onReady.bind(this)
    document.addEventListener("baka:adsense-ready", this.boundReady)
    this.onReady()
  }

  disconnect() {
    document.removeEventListener("baka:adsense-ready", this.boundReady)
    this.stopWatching()
  }

  onReady() {
    if (!this.liveValue) return
    this.tryPush()
  }

  tryPush() {
    const ins = this.adElement()
    if (!ins || ins.dataset.adsensePushed === "true") return
    if (!window.adsbygoogle) return

    try {
      ;(window.adsbygoogle = window.adsbygoogle || []).push({})
      ins.dataset.adsensePushed = "true"
      this.watchFill(ins)
    } catch (_error) {
      this.hideSlot()
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
    }, FILL_TIMEOUT_MS)
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

  showSlot() {
    this.element.classList.remove("hidden")
    if (this.placementValue === "bottom") {
      this.element.classList.add("md:block")
    }
  }

  hideSlot() {
    this.element.classList.add("hidden")
    if (this.placementValue === "bottom") {
      this.element.classList.remove("md:block")
    }
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
