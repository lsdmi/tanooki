import { Controller } from "@hotwired/stimulus"

// Live countdown label while submissions are open.
export default class extends Controller {
  static targets = ["label"]
  static values = { endsAt: String }

  connect() {
    this.tick()
    this.timer = window.setInterval(() => this.tick(), 30_000)
  }

  disconnect() {
    if (this.timer) window.clearInterval(this.timer)
  }

  tick() {
    if (!this.hasLabelTarget) return
    const ends = Date.parse(this.endsAtValue)
    if (Number.isNaN(ends)) return

    const diff = ends - Date.now()
    if (diff <= 0) {
      this.labelTarget.textContent = this.labelTarget.textContent
      return
    }

    const days = Math.floor(diff / 86_400_000)
    const hours = Math.floor((diff % 86_400_000) / 3_600_000)
    this.labelTarget.textContent = `До дедлайну · ${days}д ${hours}г`
  }
}
