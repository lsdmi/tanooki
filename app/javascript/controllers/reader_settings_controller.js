import { Controller } from "@hotwired/stimulus"
import {
  bindContentObserver,
  getFontSizeBounds,
  getSavedFontId,
  getSavedFontSize,
  setFontId,
  setFontSize
} from "reader_preferences"
import { safeLogoSrc } from "safe_logo_src"

/** Reading settings side panel (font, size, theme) on the chapter reader. */
export default class extends Controller {
  static targets = [
    "backdrop",
    "panel",
    "trigger",
    "fontOption",
    "fontSizeValue",
    "themeToggle",
    "themeLabel"
  ]

  connect() {
    this._onEscape = this._onEscape.bind(this)
    this._onTurboLoad = () => this.close()
    document.addEventListener("turbo:load", this._onTurboLoad)

    bindContentObserver()
    this.syncFontUi()
    this.syncFontSizeUi()
    this.syncThemeUi()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this._onTurboLoad)
    document.removeEventListener("keydown", this._onEscape)
    this.close()
  }

  open(event) {
    event?.preventDefault()
    event?.stopPropagation()
    if (!this.hasBackdropTarget || !this.hasPanelTarget) return

    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.add("opacity-100", "pointer-events-auto")
    this.backdropTarget.setAttribute("aria-hidden", "false")

    this.panelTarget.classList.remove("translate-x-full")
    this.panelTarget.classList.add("translate-x-0")

    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", "true")

    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this._onEscape)

    this.syncFontUi()
    this.syncFontSizeUi()
    this.syncThemeUi()
  }

  close() {
    if (!this.hasBackdropTarget || !this.hasPanelTarget) return

    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")
    this.backdropTarget.classList.remove("opacity-100", "pointer-events-auto")
    this.backdropTarget.setAttribute("aria-hidden", "true")

    this.panelTarget.classList.add("translate-x-full")
    this.panelTarget.classList.remove("translate-x-0")

    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", "false")

    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this._onEscape)
  }

  selectFont(event) {
    const fontId = event.currentTarget.dataset.fontId
    if (!fontId) return

    setFontId(fontId)
    this.syncFontUi()
  }

  decreaseFontSize() {
    setFontSize(getSavedFontSize() - 1)
    this.syncFontSizeUi()
  }

  increaseFontSize() {
    setFontSize(getSavedFontSize() + 1)
    this.syncFontSizeUi()
  }

  toggleTheme() {
    document.documentElement.classList.toggle("dark")
    const isDark = document.documentElement.classList.contains("dark")
    localStorage.setItem("color-theme", isDark ? "dark" : "light")
    document.cookie = `color_theme=${isDark ? "dark" : "light"}; path=/; max-age=31536000`
    this.updateSiteLogo(isDark)
    this.syncThemeUi()
  }

  syncFontUi() {
    const activeId = getSavedFontId()
    this.fontOptionTargets.forEach((button) => {
      const selected = button.dataset.fontId === activeId
      button.setAttribute("aria-pressed", selected ? "true" : "false")
      button.classList.toggle("reader-settings__font--active", selected)
    })
  }

  syncFontSizeUi() {
    if (!this.hasFontSizeValueTarget) return
    const { min, max } = getFontSizeBounds()
    const size = getSavedFontSize()
    this.fontSizeValueTarget.textContent = `${size}px`

    const dec = this.element.querySelector("[data-reader-settings-font-step='decrease']")
    const inc = this.element.querySelector("[data-reader-settings-font-step='increase']")
    if (dec) dec.disabled = size <= min
    if (inc) inc.disabled = size >= max
  }

  syncThemeUi() {
    const isDark = document.documentElement.classList.contains("dark")
    if (this.hasThemeToggleTarget) this.themeToggleTarget.checked = isDark
    if (this.hasThemeLabelTarget) {
      this.themeLabelTarget.textContent = isDark ? "Увімкнено" : "Вимкнено"
    }
  }

  updateSiteLogo(isDark) {
    const siteLogo = document.getElementById("site-logo")
    if (!siteLogo) return
    const defaultLogo = safeLogoSrc(siteLogo.getAttribute("data-default-logo"))
    const darkLogo = safeLogoSrc(siteLogo.getAttribute("data-dark-logo"))
    if (defaultLogo && darkLogo) siteLogo.src = isDark ? darkLogo : defaultLogo
  }

  _onEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
