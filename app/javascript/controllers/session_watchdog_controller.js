import { Controller } from "@hotwired/stimulus"

const CHECK_INTERVAL_MS = 5 * 60 * 1000

/** Polls session status on protected pages and reports unexpected logouts. */
export default class extends Controller {
  static values = {
    statusUrl: String,
    diagnosticsUrl: String,
    loginUrl: String
  }

  connect() {
    this.checking = false
    this.redirecting = false
    this.onVisibilityChange = () => {
      if (document.visibilityState === "visible") this.check()
    }

    document.addEventListener("visibilitychange", this.onVisibilityChange)
    this.intervalId = window.setInterval(() => this.check(), CHECK_INTERVAL_MS)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.onVisibilityChange)
    window.clearInterval(this.intervalId)
  }

  async check() {
    if (this.checking || this.redirecting) return

    this.checking = true
    try {
      const response = await fetch(this.statusUrlValue, {
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      })
      if (!response.ok) return

      const data = await response.json()
      if (!data.authenticated) await this.reportAndRedirect("session_lost_on_protected_page")
    } catch (_) {
      // Ignore transient network errors; the next visibility check will retry.
    } finally {
      this.checking = false
    }
  }

  async reportAndRedirect(reason) {
    if (this.redirecting) return

    this.redirecting = true
    const body = new FormData()
    body.append("reason", reason)
    body.append("page_url", window.location.href)

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      await fetch(this.diagnosticsUrlValue, {
        method: "POST",
        body,
        credentials: "same-origin",
        headers: token ? { "X-CSRF-Token": token } : {}
      })
    } catch (_) {}

    if (window.Turbo) {
      window.Turbo.visit(this.loginUrlValue)
    } else {
      window.location.href = this.loginUrlValue
    }
  }
}
