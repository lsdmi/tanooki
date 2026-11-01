import { Controller } from '@hotwired/stimulus'

/**
 * Sets a Turbo Frame +src+ the first time its host <details> opens, so closed panels stay cold.
 */
export default class extends Controller {
  static targets = ['frame']
  static values = { src: String }

  connect() {
    this.loaded = false
    if (this.element instanceof HTMLDetailsElement && this.element.open) this.load()
  }

  toggle() {
    if (this.element instanceof HTMLDetailsElement && this.element.open) this.load()
  }

  load() {
    if (this.loaded || !this.hasFrameTarget || !this.srcValue) return

    this.loaded = true
    this.frameTarget.src = this.srcValue
  }
}
