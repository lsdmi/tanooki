import { Controller } from "@hotwired/stimulus"
import { showFlashToast } from "flash_toast"

// Catch POST first; then data-catch drives Tailwind sprite animations for the server result.
export default class extends Controller {
  static targets = ["sprite"]

  async submit(event) {
    event.preventDefault()
    if (this.busy) return

    const form = event.target
    if (!(form instanceof HTMLFormElement)) return

    this.busy = true
    this.setCatchState("busy")

    try {
      const data = await this.requestCatch(form)
      await this.play(data.caught ? "success" : "failure")
      showFlashToast(data.message, data.caught ? "notice" : "alert")
      this.removeCatchUi()
    } catch {
      this.busy = false
      this.clearCatchState()
    }
  }

  async requestCatch(form) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch(form.action, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": token,
        "X-Requested-With": "XMLHttpRequest"
      },
      body: new FormData(form),
      credentials: "same-origin"
    })
    if (!response.ok) throw new Error(`catch failed: ${response.status}`)
    return response.json()
  }

  play(kind) {
    if (this.reducedMotion) return Promise.resolve()

    return new Promise((resolve) => {
      const finish = () => {
        this.element.removeEventListener("animationend", onEnd)
        window.clearTimeout(fallback)
        resolve()
      }
      const onEnd = (event) => {
        if (event.target === this.spriteTarget) finish()
      }

      this.setCatchState(kind)
      this.element.addEventListener("animationend", onEnd)
      const fallback = window.setTimeout(finish, 1100)
    })
  }

  setCatchState(state) {
    this.element.dataset.catch = state
  }

  clearCatchState() {
    delete this.element.dataset.catch
  }

  removeCatchUi() {
    const frame = this.element.closest("turbo-frame#catch-pokemon")
    ;(frame || this.element).remove()
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
