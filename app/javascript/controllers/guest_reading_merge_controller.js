import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { mergeBatch } from "guest_reading"
import { deleteRecords, readAllRecords } from "guest_reading_store"

let merging = false

// Signed-in pages only: folds what this device read as a guest into the account (`GuestReadingMergesController`).
// Mounted on every signed-in page rather than on sign-in, so remember-me, OAuth and sign-up all merge too, and a
// failed post simply retries on the next page. Records leave the device only after the server answers 200.
export default class extends Controller {
  static values = { url: String }

  async connect() {
    if (merging) return

    merging = true
    try {
      await this.merge()
    } finally {
      merging = false
    }
  }

  async merge() {
    const { batch, body } = mergeBatch(await readAllRecords())
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    if (!batch.length || !token) return

    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        "X-Requested-With": "XMLHttpRequest"
      },
      body: JSON.stringify(body),
      credentials: "same-origin"
    }).catch(() => null)
    if (response?.status !== 200) return

    const { merged } = await response.json().catch(() => ({}))
    await deleteRecords(batch)
    if (!merged) return

    Turbo.cache.clear()
    if (this.element.isConnected) Turbo.visit(window.location.href, { action: "replace" })
  }
}
