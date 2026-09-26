import { Controller } from "@hotwired/stimulus"
import { resolveResumeTarget } from "reading_resume"

const BLOCK_MARGIN_PX = 16
const SETTLE_TIMEOUT_MS = 4000
const ANCHOR_MIN_MS = 1500
const BANNER_HIDE_PERCENT = 15
const READER_INPUTS = ["wheel", "touchstart", "keydown", "mousedown"]
const RESUME_PARAM = "resume"
const HOLD_ATTRIBUTE = "data-reading-progress-hold-value"

// Brings the reader back to where they stopped in the chapter the resume cursor is on.
// Opened from «Читати далі» (?resume=1, auto) it restores straight away. Any other visit shows a banner:
// «Продовжити з N%» runs the same restore, «З початку» or scrolling past 15% dismisses it. The server renders
// the reading-progress hold with the banner, so nothing overwrites the saved place until the reader answers.
// Fonts and images above the target can still shift layout: until they settle the target is re-anchored on
// every content resize, then once more on the next frame. Any reader input ends it. The resume flag leaves the
// URL and the controller detaches when done, so reload, Back and Turbo snapshots never jump again.
export default class extends Controller {
  static targets = ["banner"]
  static values = { quote: String, blockIndex: Number, percent: Number, digest: String, auto: Boolean }

  connect() {
    this.content = this.element.querySelector("#user-content")
    if (!this.content) return this.finish()

    this.destination = resolveResumeTarget(this.readBlocks(), this.locator(), this.content.dataset.rpDigest)
    if (!this.destination) return this.finish()

    if (this.autoValue) {
      this.dropResumeParam()
      this.restore()
    } else {
      this.offer()
    }
  }

  disconnect() {
    this.release()
  }

  resume() {
    this.hideBanner()
    this.restore()
  }

  dismiss() {
    this.finish()
  }

  // A Back visit or a morph can reconnect with the reader already scrolled into the chapter.
  offer() {
    if (!this.hasBannerTarget || this.readPercent() >= BANNER_HIDE_PERCENT) return this.finish()

    this.bannerTarget.hidden = false
    this.onScroll = () => {
      if (this.readPercent() >= BANNER_HIDE_PERCENT) this.finish()
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })
  }

  hideBanner() {
    if (this.hasBannerTarget) this.bannerTarget.hidden = true
    if (!this.onScroll) return

    window.removeEventListener("scroll", this.onScroll)
    this.onScroll = null
  }

  restore() {
    this.watchReaderInput()
    this.scrollToTarget()
    this.anchor = new ResizeObserver(() => this.scrollToTarget())
    this.anchor.observe(this.content)
    const minimum = new Promise((resolve) => setTimeout(resolve, ANCHOR_MIN_MS))
    Promise.all([this.settled(), minimum]).then(() => requestAnimationFrame(() => {
      if (this.anchor) this.scrollToTarget()
      this.finish()
    }))
  }

  readPercent() {
    const rect = this.content.getBoundingClientRect()
    return rect.height > 0 ? (-rect.top / rect.height) * 100 : 0
  }

  locator() {
    return {
      quote: this.quoteValue,
      blockIndex: this.hasBlockIndexValue ? this.blockIndexValue : null,
      percent: this.hasPercentValue ? this.percentValue : null,
      digest: this.digestValue
    }
  }

  readBlocks() {
    return Array.from(this.content.querySelectorAll("[data-rp-i]"), (element) => ({
      index: Number(element.dataset.rpI),
      text: element.textContent
    }))
  }

  scrollToTarget() {
    const top = this.destinationTop()
    if (top === null || Math.abs(top - window.scrollY) < 2) return

    window.scrollTo({ top, behavior: "instant" })
  }

  destinationTop() {
    if (this.destination.type === "block") {
      const block = this.content.querySelector(`[data-rp-i="${this.destination.index}"]`)
      if (!block) return null

      return block.getBoundingClientRect().top + window.scrollY - this.toolbarInset() - BLOCK_MARGIN_PX
    }

    const rect = this.content.getBoundingClientRect()
    return rect.top + window.scrollY + (rect.height * this.destination.percent) / 100 - this.toolbarInset()
  }

  // The sticky toolbar connects after this controller, so it never sees the jump as a scroll down and
  // stays over the top of the viewport.
  toolbarInset() {
    const toolbar = this.element.querySelector("[data-controller~='reader-toolbar']")
    return toolbar ? Math.max(0, toolbar.getBoundingClientRect().bottom) : 0
  }

  settled() {
    const loaded = document.readyState === "complete"
      ? Promise.resolve()
      : new Promise((resolve) => window.addEventListener("load", resolve, { once: true }))
    const fonts = document.fonts?.ready ?? Promise.resolve()
    const timeout = new Promise((resolve) => setTimeout(resolve, SETTLE_TIMEOUT_MS))
    return Promise.race([Promise.all([loaded, fonts]), timeout])
  }

  watchReaderInput() {
    this.onReaderInput = () => this.finish()
    for (const type of READER_INPUTS) {
      window.addEventListener(type, this.onReaderInput, { passive: true })
    }
  }

  release() {
    this.hideBanner()
    this.anchor?.disconnect()
    this.anchor = null
    if (!this.onReaderInput) return

    for (const type of READER_INPUTS) {
      window.removeEventListener(type, this.onReaderInput)
    }
    this.onReaderInput = null
  }

  dropResumeParam() {
    const url = new URL(window.location.href)
    if (!url.searchParams.has(RESUME_PARAM)) return

    url.searchParams.delete(RESUME_PARAM)
    window.history.replaceState(window.history.state, "", url)
  }

  // Detaching keeps a Turbo snapshot of this page from restoring again when it is shown later.
  finish() {
    this.release()
    this.element.removeAttribute(HOLD_ATTRIBUTE)
    const controllers = (this.element.dataset.controller || "").split(/\s+/).filter((name) => name !== this.identifier)
    this.element.dataset.controller = controllers.join(" ")
  }
}
