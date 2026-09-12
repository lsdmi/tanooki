import { Controller } from "@hotwired/stimulus"

const NEXT_SLOT = { front: "left", left: "right", right: "front" }
const INITIAL_SLOTS = ["front", "left", "right"]
const DESKTOP_HOVER = "(min-width: 1024px) and (hover: hover) and (pointer: fine)"

// Cycles genre spotlight covers on desktop hover and restores the resting deck on leave.
export default class extends Controller {
  static targets = ["cover"]
  static values = { interval: { type: Number, default: 850 } }

  connect() {
    this.desktopHover = window.matchMedia(DESKTOP_HOVER)
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)")
    this.onEnter = this.start.bind(this)
    this.onLeave = this.stop.bind(this)
    this.element.addEventListener("pointerenter", this.onEnter)
    this.element.addEventListener("pointerleave", this.onLeave)
  }

  disconnect() {
    this.stop()
    this.element.removeEventListener("pointerenter", this.onEnter)
    this.element.removeEventListener("pointerleave", this.onLeave)
  }

  start() {
    if (!this.canAnimate()) return

    this.cycle()
    this.timer = window.setInterval(() => this.cycle(), this.intervalValue)
  }

  stop() {
    if (this.timer) {
      window.clearInterval(this.timer)
      this.timer = null
    }
    this.resetSlots()
  }

  canAnimate() {
    return this.hasCoverTarget &&
      this.coverTargets.length >= 2 &&
      this.desktopHover.matches &&
      !this.reducedMotion.matches
  }

  cycle() {
    this.coverTargets.forEach((cover) => {
      cover.dataset.slot = NEXT_SLOT[cover.dataset.slot] || "front"
    })
  }

  resetSlots() {
    this.coverTargets.forEach((cover, index) => {
      cover.dataset.slot = INITIAL_SLOTS[index] || "front"
    })
  }
}
