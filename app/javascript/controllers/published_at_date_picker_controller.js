import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

// Official flatpickr Ukrainian locale (dist/l10n/uk)
const ukrainianLocale = {
  firstDayOfWeek: 1,
  weekdays: {
    shorthand: ["Нд", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"],
    longhand: [
      "Неділя",
      "Понеділок",
      "Вівторок",
      "Середа",
      "Четвер",
      "П'ятниця",
      "Субота",
    ],
  },
  months: {
    shorthand: [
      "Січ",
      "Лют",
      "Бер",
      "Кві",
      "Тра",
      "Чер",
      "Лип",
      "Сер",
      "Вер",
      "Жов",
      "Лис",
      "Гру",
    ],
    longhand: [
      "Січень",
      "Лютий",
      "Березень",
      "Квітень",
      "Травень",
      "Червень",
      "Липень",
      "Серпень",
      "Вересень",
      "Жовтень",
      "Листопад",
      "Грудень",
    ],
  },
  time_24hr: true,
}

export default class extends Controller {
  connect() {
    const el = this.element
    if (el._flatpickr) {
      el._flatpickr.destroy()
    }

    // Default append to document.body — appendTo on a small wrapper breaks positioning/clipping on first open
    this.fp = flatpickr(el, {
      dateFormat: "Y-m-d",
      locale: ukrainianLocale,
      allowInput: true,
      disableMobile: true,
    })

    this.form = el.closest("form")
    this.onFormSubmit = this.destroyPickerAndStripPortal.bind(this)
    this.form?.addEventListener("submit", this.onFormSubmit, true)
  }

  disconnect() {
    this.form?.removeEventListener("submit", this.onFormSubmit, true)
    this.destroyPickerAndStripPortal()
  }

  destroyPickerAndStripPortal() {
    if (this.fp) {
      try {
        this.fp.destroy()
      } finally {
        this.fp = null
      }
    }
    document.querySelectorAll(".flatpickr-calendar").forEach((node) => node.remove())
  }
}
