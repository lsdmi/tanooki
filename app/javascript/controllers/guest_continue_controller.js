import { Controller } from "@hotwired/stimulus"
import { continueTarget } from "guest_reading"
import { readRecord } from "guest_reading_store"

// The fiction page CTA for guests. Their page is a shared cached fragment, so «Продовжити» comes from this
// device's reading record after connect. With no record, or the latest chapter read, it stays «Читати» from the
// first chapter. Recomputed on every connect, so a Turbo snapshot never shows a stale target.
export default class extends Controller {
  static targets = ["link", "label"]
  static values = { fictionId: Number, latestChapterId: Number, readPath: String, readLabel: String, continueLabel: String }

  async connect() {
    const record = await readRecord(this.fictionIdValue)
    if (!this.element.isConnected) return

    const target = continueTarget(record, { latestChapterId: this.latestChapterIdValue })
    this.linkTarget.href = target ? target.path : this.readPathValue
    this.labelTarget.textContent = target ? this.continueLabelValue : this.readLabelValue
  }
}
