import { Controller } from "@hotwired/stimulus"

const DONE_MS = 2500

// On the latest chapter: offers to move the fiction to «Прочитано» when `reading-progress` reports this chapter
// newly completed. A completion answered after a morph to another chapter carries that chapter's url, so it is
// ignored here. Shown at most once per visit; the status is only ever set by the confirm button.
export default class extends Controller {
  static targets = ["text", "actions"]
  static values = { chapterUrl: String, doneText: String }

  disconnect() {
    clearTimeout(this.timer)
  }

  show({ detail }) {
    if (this.answered || detail.url !== this.chapterUrlValue) return

    this.element.hidden = false
  }

  hide() {
    this.answered = true
    this.element.hidden = true
  }

  finished({ detail }) {
    if (!detail.success) return this.hide()

    this.answered = true
    this.textTarget.textContent = this.doneTextValue
    this.actionsTarget.hidden = true
    this.timer = setTimeout(() => this.hide(), DONE_MS)
  }
}
