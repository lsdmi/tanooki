import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const MIN_DWELL_MS = 4000
const ENGAGED_DWELL_MS = 8000
const ENGAGED_DWELL_SEEN = 0.15
const ENGAGED_SCROLL_SEEN = 0.25
const COMPLETED_SEEN = 0.9
const NEXT_SEEN = 0.7
const TICK_MS = 1000

// Records reading from the chapter page: "engaged" moves the resume cursor, "completed" adds
// this chapter to the sparse read set. Completion always implies engagement first.
// Dwell counts only while the tab is visible and #user-content is on screen and unlocked.
// "Seen" is the furthest fraction of #user-content that has entered the viewport; ads,
// comments and the support card sit outside it and do not count.
// One-screen chapters are fully "seen" on load, so for them only dwell proves reading.
// Turbo prefetch fetches HTML without connecting Stimulus, so prefetch never records.
export default class extends Controller {
  static values = { url: String }

  // A Turbo visit keeps this page on screen until the next one renders; that wait is not reading.
  connect() {
    this.onVisit = () => this.stop()
    this.onLoad = () => this.start()
    document.addEventListener("turbo:visit", this.onVisit)
    document.addEventListener("turbo:load", this.onLoad)
    this.start()
  }

  disconnect() {
    document.removeEventListener("turbo:visit", this.onVisit)
    document.removeEventListener("turbo:load", this.onLoad)
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

    this.observer = new IntersectionObserver(([entry]) => {
      this.inView = entry.isIntersecting
      this.measure()
    })
    this.observer.observe(this.content)

    // Font size / family changes resize #user-content without a window resize.
    this.onScroll = () => this.scheduleMeasure()
    this.resizeObserver = new ResizeObserver(this.onScroll)
    this.resizeObserver.observe(this.content)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.onScroll, { passive: true })

    this.onVisibility = () => { this.lastTick = performance.now() }
    document.addEventListener("visibilitychange", this.onVisibility)

    this.timer = setInterval(() => this.tick(), TICK_MS)
  }

  stop() {
    clearInterval(this.timer)
    this.observer?.disconnect()
    this.resizeObserver?.disconnect()
    if (this.onScroll) {
      window.removeEventListener("scroll", this.onScroll)
      window.removeEventListener("resize", this.onScroll)
    }
    if (this.onVisibility) document.removeEventListener("visibilitychange", this.onVisibility)
    if (this.frame) cancelAnimationFrame(this.frame)
    this.timer = this.observer = this.resizeObserver = this.onScroll = this.onVisibility = this.frame = null
    this.trackedUrl = null
  }

  tick() {
    const now = performance.now()
    const elapsed = Math.min(now - this.lastTick, TICK_MS * 2)
    this.lastTick = now

    if (this.readable()) this.dwellMs += elapsed
    this.measure()
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
    this.send({ event: "engaged" })
  }

  complete(source) {
    this.completed = true
    this.send({ event: "completed", source })
  }

  // Sequential so "completed" never races "engaged" when both create the library row.
  send(payload) {
    const url = this.urlValue
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    if (!token) return

    this.queue = (this.queue || Promise.resolve()).then(() =>
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
          if (response.status === 200) Turbo.cache.clear()
        })
        .catch(() => {
          // Ignore network errors; reading the chapter again on a later visit retries.
        })
    )
  }
}
