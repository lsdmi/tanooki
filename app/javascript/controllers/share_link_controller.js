import { Controller } from "@hotwired/stimulus"

/** Native share when available; otherwise copy the page URL to the clipboard. */
export default class extends Controller {
  static targets = ["label"]
  static values = {
    url: String,
    title: String,
    text: String,
    copied: String,
    idle: String
  }

  async share(event) {
    event.preventDefault()
    const payload = {
      title: this.titleValue,
      text: this.textValue,
      url: this.urlValue || window.location.href
    }

    if (navigator.share) {
      try {
        await navigator.share(payload)
        return
      } catch (error) {
        if (error?.name === "AbortError") return
      }
    }

    await this.copy(payload.url)
  }

  async copy(url) {
    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(url)
      } else {
        window.prompt(this.idleValue, url)
        return
      }
    } catch {
      window.prompt(this.idleValue, url)
      return
    }

    this.flash()
  }

  flash() {
    if (!this.hasLabelTarget) return

    const previous = this.labelTarget.textContent
    this.labelTarget.textContent = this.copiedValue
    window.setTimeout(() => {
      this.labelTarget.textContent = previous
    }, 1500)
  }
}
