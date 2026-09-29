import { Controller } from "@hotwired/stimulus"
import { resumeLocator } from "guest_reading"
import { readRecord } from "guest_reading_store"

const HOLD_ATTRIBUTE = "data-reading-progress-hold-value"

// In-chapter resume for guests. The server can't see this device's reading record, so this looks it up and
// mounts `reading-resume` with the stored place, as the server does for signed-in readers: ?resume=1 restores
// straight away, any other visit gets the banner (rendered hidden for guests) and holds position capture.
export default class extends Controller {
  static targets = ["label"]
  static values = { fictionId: Number, chapterId: Number, label: String }

  // Runs on connect too; a refresh morph that swaps the chapter changes the value without reconnecting.
  async chapterIdValueChanged() {
    const chapterId = this.chapterIdValue
    const auto = new URL(window.location.href).searchParams.get("resume") === "1"
    const record = await readRecord(this.fictionIdValue)
    if (!this.element.isConnected || chapterId !== this.chapterIdValue) return

    const locator = resumeLocator(record, chapterId, { auto })
    if (locator) this.mount(locator, auto)
  }

  mount(locator, auto) {
    const data = this.element.dataset
    data.readingResumeAutoValue = String(auto)
    data.readingResumePercentValue = String(locator.percent)
    if (locator.quote) data.readingResumeQuoteValue = locator.quote
    if (Number.isInteger(locator.block_index)) data.readingResumeBlockIndexValue = String(locator.block_index)
    if (locator.digest) data.readingResumeDigestValue = locator.digest
    if (!auto) {
      this.element.setAttribute(HOLD_ATTRIBUTE, "true")
      if (this.hasLabelTarget) {
        this.labelTarget.textContent = this.labelValue.replace("{percent}", Math.round(locator.percent))
      }
    }
    data.controller = `${data.controller} reading-resume`
  }
}
