import { Controller } from "@hotwired/stimulus"

const FILL_TIMEOUT_MS = 10000

// Pushes AdSense for one unit. Slot must stay visible until the request runs (hidden = no fill).
// Collapses the wrapper only when Google marks the unit unfilled or nothing fills in time.
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
      this.collapseSlot()
    }
  }

  watchFill(ins) {
    this.stopWatching()

    const resolved = () => {
      if (this.isFilled(ins)) {
        this.expandSlot()
        return true
      }
      if (this.isUnfilled(ins)) {
        this.collapseSlot()
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
      if (!this.isFilled(ins)) this.collapseSlot()
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

  expandSlot() {
    this.element.classList.remove("reader-ad-slot--collapsed")
    if (this.placementValue === "bottom") {
      this.element.classList.add("md:block")
    }
  }

  collapseSlot() {
    this.element.classList.add("reader-ad-slot--collapsed")
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
