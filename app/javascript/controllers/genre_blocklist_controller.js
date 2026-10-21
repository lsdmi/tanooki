import { Controller } from "@hotwired/stimulus"

// Filters the server-rendered genre list as the reader types. Checked genres stay visible.
export default class extends Controller {
  static targets = ["query", "option", "empty"]

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()
    let visible = 0

    this.optionTargets.forEach((option) => {
      const checked = option.querySelector("input").checked
      const match = checked || option.dataset.name.includes(query)
      option.classList.toggle("hidden", !match)
      if (match) visible += 1
    })

    this.emptyTarget.classList.toggle("hidden", visible > 0)
  }

  preventSubmit(event) {
    if (event.key === "Enter") event.preventDefault()
  }
}
