import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select"
import { connectSlimSelect, disconnectSlimSelect } from "slim_select_lifecycle"
import { findSameTag, normalizeTagName, tagNameProblem } from "fiction_tag_name"

// Connects to data-controller="fiction-tags" on the «Теґи» <select multiple> in the fiction form.
// Option values are tag names: the server finds an existing tag by name or creates a new one (FictionTags::Sync).
// A status element (data-fiction-tags-status-id-value) holds a [data-counter] and a [data-message] span.
const MESSAGES = {
  empty: () => "",
  too_long: ({ maxLength }) => `Теґ задовгий: не більше ${maxLength} символів.`,
  too_many: ({ max }) => `Можна додати не більше ${max} теґів.`,
}

export default class extends Controller {
  static values = {
    max: { type: Number, default: 10 },
    maxLength: { type: Number, default: 40 },
    statusId: String,
    counterTemplate: String,
  }

  connect() {
    connectSlimSelect(this, () => new SlimSelect({
      select: this.element,
      settings: {
        closeOnSelect: false,
        maxSelected: this.maxValue,
        placeholderText: "Додайте теґи",
        searchPlaceholder: "Знайти або створити теґ",
        searchText: "Нічого не знайдено. Натисніть «+» або Ctrl+Enter, щоб створити теґ",
      },
      events: {
        addable: (value) => this.add(value),
        // getSelected() still returns the previous selection inside afterChange; the event carries the new one.
        afterChange: (selectedOptions) => this.refresh(selectedOptions.length),
      },
    }))
    this.refresh()
  }

  disconnect() {
    disconnectSlimSelect(this)
  }

  // Returning a string makes SlimSelect create and select that option; false cancels.
  add(value) {
    const name = normalizeTagName(value)
    const problem = tagNameProblem(name, {
      selectedCount: this.selectedValues().length,
      max: this.maxValue,
      maxLength: this.maxLengthValue,
    })
    if (problem) return this.reject(problem)

    const existing = findSameTag(this.optionValues(), name)
    if (existing === undefined) return name

    this.select.setSelected([...new Set([...this.selectedValues(), existing])])
    this.select.search("")
    return false
  }

  reject(problem) {
    this.showMessage(MESSAGES[problem]({ max: this.maxValue, maxLength: this.maxLengthValue }))
    return false
  }

  refresh(count = this.selectedValues().length) {
    // Chips can wrap onto a new row; SlimSelect re-places an open dropdown on window resize.
    requestAnimationFrame(() => window.dispatchEvent(new Event("resize")))
    this.showMessage("")
    const counter = this.statusElement()?.querySelector("[data-counter]")
    if (counter) {
      counter.textContent = this.counterTemplateValue
        .replace("__CURRENT__", count)
        .replace("__MAX__", this.maxValue)
    }
  }

  showMessage(text) {
    const target = this.statusElement()?.querySelector("[data-message]")
    if (target) target.textContent = text
  }

  statusElement() {
    return this.hasStatusIdValue ? document.getElementById(this.statusIdValue) : null
  }

  selectedValues() {
    return this.select ? this.select.getSelected() : [...this.element.selectedOptions].map((option) => option.value)
  }

  optionValues() {
    return [...this.element.options].map((option) => option.value)
  }
}
