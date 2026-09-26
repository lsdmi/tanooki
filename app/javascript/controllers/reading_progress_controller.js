import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const MIN_DWELL_MS = 4000
const ENGAGED_DWELL_MS = 8000
const ENGAGED_DWELL_SEEN = 0.15
const ENGAGED_SCROLL_SEEN = 0.25
const COMPLETED_SEEN = 0.9
const NEXT_SEEN = 0.7
const TICK_MS = 1000
const POSITION_DEBOUNCE_MS = 1000
const POSITION_FLUSH_MS = 5000
const QUOTE_LENGTH = 120

// Records reading from the chapter page: "engaged" moves the resume cursor, "completed" adds
// this chapter to the sparse read set. Completion always implies engagement first.
// Dwell counts only while the tab is visible and #user-content is on screen and unlocked.
// "Seen" is the furthest fraction of #user-content that has entered the viewport; ads,
// comments and the support card sit outside it and do not count.
// One-screen chapters are fully "seen" on load, so for them only dwell proves reading.
// Turbo prefetch fetches HTML without connecting Stimulus, so prefetch never records.
//
// Once engaged, the in-chapter position (first visible [data-rp-i] block, its quote, percent and
// the content digest) is captured 1s after scrolling settles and sent as "position" at most every
// 5s, plus when the tab hides or the reader leaves. The hold value pauses capture (resume banner).
export default class extends Controller {
  static values = { url: String, hold: Boolean }

  // A Turbo visit keeps this page on screen until the next one renders; that wait is not reading.
  connect() {
    this.onVisit = () => {
      this.capturePosition()
      this.stop()
    }
    this.onLoad = () => this.start()
    this.onPageHide = () => {
      this.capturePosition()
      this.flushPosition({ now: true })
    }
    document.addEventListener("turbo:visit", this.onVisit)
    document.addEventListener("turbo:load", this.onLoad)
    window.addEventListener("pagehide", this.onPageHide)
    this.start()
  }

  disconnect() {
    document.removeEventListener("turbo:visit", this.onVisit)
    document.removeEventListener("turbo:load", this.onLoad)
    window.removeEventListener("pagehide", this.onPageHide)
    this.stop()
  }

  // Chapter-to-chapter navigation can morph the same element; restart for the new chapter.
  urlValueChanged() {
    if (this.trackedUrl && this.trackedUrl !== this.urlValue) this.stop()
    if (this.element.isConnected) this.start()
  }

  // «Наступний розділ»: counts as finishing only past NEXT_SEEN (or after the one-screen dwell).
  next() {
    if (!this.trackedUrl || this.completed) return

    const rect = this.measureSeen()
    if (!rect || !this.isEngaged(rect)) return

    this.engage()
    if (this.fits(rect) || this.seen >= NEXT_SEEN) this.complete("next")
  }

  // Drawer read toggles answer with a Turbo Stream, which leaves stale library snapshots in the Turbo cache.
  clearCache(event) {
    if (event.detail?.success) Turbo.cache.clear()
  }

  start() {
    if (this.trackedUrl === this.urlValue || !this.urlValue) return

    this.content = this.element.querySelector("#user-content")
    if (!this.content) return

    this.trackedUrl = this.urlValue
    this.engaged = false
    this.completed = false
    this.dwellMs = 0
    this.seen = 0
    this.inView = false
    this.lastTick = performance.now()
    this.blocks = null
    this.locator = null
    this.sentLocator = null
    this.lastFlush = performance.now()

    this.observer = new IntersectionObserver(([entry]) => {
      this.inView = entry.isIntersecting
      this.measure()
    })
    this.observer.observe(this.content)

    // Font size / family changes resize #user-content without a window resize.
    this.onScroll = () => {
      this.scheduleMeasure()
      this.schedulePosition()
    }
    this.resizeObserver = new ResizeObserver(this.onScroll)
    this.resizeObserver.observe(this.content)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.onScroll, { passive: true })

    this.onVisibility = () => {
      this.lastTick = performance.now()
      if (document.visibilityState === "hidden") this.flushPosition({ now: true })
    }
    document.addEventListener("visibilitychange", this.onVisibility)

    this.timer = setInterval(() => this.tick(), TICK_MS)
  }

  // Sends the last captured position without measuring again: after a morph the content is already the next chapter.
  stop() {
    this.flushPosition()
    clearInterval(this.timer)
    clearTimeout(this.positionTimer)
    this.observer?.disconnect()
    this.resizeObserver?.disconnect()
    if (this.onScroll) {
      window.removeEventListener("scroll", this.onScroll)
      window.removeEventListener("resize", this.onScroll)
    }
    if (this.onVisibility) document.removeEventListener("visibilitychange", this.onVisibility)
    if (this.frame) cancelAnimationFrame(this.frame)
    this.timer = this.observer = this.resizeObserver = this.onScroll = this.onVisibility = this.frame = null
    this.positionTimer = null
    this.trackedUrl = null
  }

  tick() {
    const now = performance.now()
    const elapsed = Math.min(now - this.lastTick, TICK_MS * 2)
    this.lastTick = now

    if (this.readable()) this.dwellMs += elapsed
    this.measure()
    if (now - this.lastFlush >= POSITION_FLUSH_MS) this.flushPosition()
  }

  schedulePosition() {
    clearTimeout(this.positionTimer)
    this.positionTimer = setTimeout(() => this.capturePosition(), POSITION_DEBOUNCE_MS)
  }

  capturePosition() {
    if (!this.trackedUrl || !this.engaged || this.holdValue || !this.readable()) return

    const rect = this.content.getBoundingClientRect()
    if (rect.height <= 0) return

    // Once this visit completed the chapter the position reports 100% so «Читати далі» moves on; the block and
    // quote still name the line on screen for a restore.
    const percent = this.completed ? 100 : Math.min(100, Math.max(0, (-rect.top / rect.height) * 100))
    const block = this.firstVisibleBlock()
    this.locator = {
      percent: Math.round(percent * 100) / 100,
      block_index: block ? Number(block.dataset.rpI) : null,
      quote: block ? block.textContent.replace(/\s+/g, " ").trim().slice(0, QUOTE_LENGTH) : null,
      digest: this.content.dataset.rpDigest || null
    }
  }

  // Blocks are in document order, so their bottoms only grow: binary search for the first one below the viewport top.
  firstVisibleBlock() {
    this.blocks ??= Array.from(this.content.querySelectorAll("[data-rp-i]"))
    let low = 0
    let high = this.blocks.length - 1
    let found = null
    while (low <= high) {
      const mid = (low + high) >> 1
      if (this.blocks[mid].getBoundingClientRect().bottom > 0) {
        found = this.blocks[mid]
        high = mid - 1
      } else {
        low = mid + 1
      }
    }
    return found
  }

  flushPosition({ now = false } = {}) {
    this.lastFlush = performance.now()
    if (!this.trackedUrl || !this.locator) return

    const key = JSON.stringify(this.locator)
    if (key === this.sentLocator) return

    this.sentLocator = key
    this.send({ event: "position", locator: this.locator }, { now })
  }

  scheduleMeasure() {
    if (this.frame) return

    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.measure()
    })
  }

  measure() {
    if (this.completed) return

    const rect = this.measureSeen()
    if (!rect || !this.isEngaged(rect)) return

    this.engage()
    if (this.fits(rect) || this.seen >= COMPLETED_SEEN) this.complete("scroll")
  }

  measureSeen() {
    if (!this.content) return null

    const rect = this.content.getBoundingClientRect()
    if (rect.height <= 0) return null

    if (this.readable()) {
      const seen = (window.innerHeight - rect.top) / rect.height
      this.seen = Math.max(this.seen, Math.min(1, Math.max(0, seen)))
    }
    return rect
  }

  readable() {
    return document.visibilityState === "visible" &&
      this.inView &&
      !this.content.closest(".adult-content-gate--locked")
  }

  // Re-evaluated on every measure: resize or a font change can flip a chapter in or out of one screen.
  fits(rect) {
    return rect.height <= window.innerHeight
  }

  isEngaged(rect) {
    if (this.dwellMs < MIN_DWELL_MS) return false
    if (this.fits(rect)) return this.dwellMs >= ENGAGED_DWELL_MS

    return (this.dwellMs >= ENGAGED_DWELL_MS && this.seen >= ENGAGED_DWELL_SEEN) ||
      this.seen >= ENGAGED_SCROLL_SEEN
  }

  engage() {
    if (this.engaged) return

    this.engaged = true
    this.capturePosition()
    if (this.locator) this.sentLocator = JSON.stringify(this.locator)
    this.send({ event: "engaged", locator: this.locator })
  }

  complete(source) {
    this.completed = true
    this.send({ event: "completed", source })
  }

  // Sequential so "completed" never races "engaged" when both create the library row.
  // Posts to the tracked chapter: after a morph, urlValue already names the next one.
  // A page being hidden or unloaded may not run queued callbacks, so `now` skips the queue.
  send(payload, { now = false } = {}) {
    const url = this.trackedUrl || this.urlValue
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    if (!token) return

    const post = () =>
      fetch(url, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
          "X-Requested-With": "XMLHttpRequest"
        },
        body: JSON.stringify(payload),
        credentials: "same-origin",
        keepalive: true
      })
        .then((response) => {
          if (response.status === 200 && payload.event !== "position") Turbo.cache.clear()
        })
        .catch(() => {
          // Ignore network errors; reading the chapter again on a later visit retries.
        })

    if (now) {
      post()
    } else {
      this.queue = (this.queue || Promise.resolve()).then(post)
    }
  }
}
