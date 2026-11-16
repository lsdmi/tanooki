import { Controller } from "@hotwired/stimulus"

const CHECK_PATH = '<path d="M20 6 9 17l-5-5"></path>'

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

  #flashTimer = null
  #idleButton = null

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

    await this.copy(payload.url, event.currentTarget)
  }

  /** Clipboard only — no native share sheet. */
  async copyUrl(event) {
    event.preventDefault()
    await this.copy(this.urlValue || window.location.href, event.currentTarget)
  }

  async copy(url, trigger = null) {
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

    this.flash(trigger)
  }

  flash(trigger = null) {
    if (this.#flashTimer) window.clearTimeout(this.#flashTimer)

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = this.copiedValue
    }

    const button = trigger?.closest?.("button") || trigger
    if (!(button instanceof HTMLElement)) {
      this.#flashTimer = window.setTimeout(() => this.#restoreLabel(), 1500)
      return
    }

    if (!this.#idleButton) {
      this.#idleButton = {
        ariaLabel: button.getAttribute("aria-label") || this.idleValue,
        title: button.getAttribute("title"),
        className: button.getAttribute("class") || "",
        iconHtml: button.querySelector("svg")?.innerHTML || null
      }
    }

    button.setAttribute("aria-label", this.copiedValue)
    if (button.hasAttribute("title")) button.setAttribute("title", this.copiedValue)

    const icon = button.querySelector("svg")
    if (icon && this.#idleButton.iconHtml) icon.innerHTML = CHECK_PATH
    button.classList.remove("text-fg-muted", "hover:text-fg")
    button.classList.add("text-status-success-solid", "scale-110")

    this.#flashTimer = window.setTimeout(() => {
      this.#restoreLabel()
      button.setAttribute("aria-label", this.#idleButton.ariaLabel)
      if (this.#idleButton.title != null) button.setAttribute("title", this.#idleButton.title)
      if (icon && this.#idleButton.iconHtml) icon.innerHTML = this.#idleButton.iconHtml
      button.setAttribute("class", this.#idleButton.className)
      this.#idleButton = null
      this.#flashTimer = null
    }, 1500)
  }

  #restoreLabel() {
    if (this.hasLabelTarget) this.labelTarget.textContent = this.idleValue
  }
}
