import { Controller } from "@hotwired/stimulus"

/**
 * Catalog drawer tag list. Without a query only the featured tags and the checked ones show;
 * a query narrows the list to matching tags across all of them. Checked tags that do not match
 * are hidden but stay checked, so they still apply when the form is submitted.
 * The chips are inline-flex, which wins over Tailwind's .hidden, so this uses the hidden attribute.
 */
export default class extends Controller {
  static targets = ["input", "item", "empty"]

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    let matches = 0

    this.itemTargets.forEach((item) => {
      const checked = item.querySelector("input[type='checkbox']")?.checked === true
      const matched = query !== "" && item.dataset.name.includes(query)
      if (matched) matches += 1

      const show = query === "" ? checked || item.dataset.featured === "true" : matched
      item.hidden = !show
    })

    this.emptyTarget.hidden = query === "" || matches > 0
  }
}
