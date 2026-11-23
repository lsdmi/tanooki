import { Controller } from "@hotwired/stimulus"

// "Як у останнього розділу": copies the latest chapter's publish date and time into the schedule fields.
export default class extends Controller {
  static targets = ["date", "time"]

  apply(event) {
    const { date, time } = event.params
    if (this.hasDateTarget) this.setDate(date)
    if (this.hasTimeTarget) this.setTime(time)
  }

  setDate(value) {
    const input = this.dateTarget
    if (input._flatpickr) {
      input._flatpickr.setDate(value, false)
    } else {
      input.value = value
    }
    input.dispatchEvent(new Event("change", { bubbles: true }))
  }

  setTime(value) {
    const select = this.timeTarget
    // Legacy or off-grid times have no option yet; add one so the select can show them.
    if (![...select.options].some((option) => option.value === value)) {
      select.add(new Option(value, value))
    }
    select.value = value
    select.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
