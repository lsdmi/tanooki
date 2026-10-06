import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { showErrorMessage, showUndoToast } from "flash_toast"

const LONG_PRESS_MS = 500
const MOVE_TOLERANCE_PX = 10
const REOPEN_GUARD_MS = 300
const ROW = "li[data-chapter-id][data-chapter-key]"
const TOGGLE = "form[data-controller~='read-toggle']"

/**
 * Row actions on the fiction page Chapters tab (Figma 10163:12883, 10163:19917): one shared Ui::BottomSheetComponent
 * opened from a row's ⋮ (desktop hover) or a long-press on the row (touch). Single read / unread submits the row's
 * read toggle, so it gets the same optimistic swap and undo. «Позначити прочитаними 1–85» posts to the read-through
 * endpoint; its JSON reply carries the toast text, the undo token and Turbo Streams for the loaded rows.
 */
export default class extends Controller {
  static targets = ["anchor", "sheet", "markRead", "markThrough", "markUnread"]
  static values = { url: String }

  connect() {
    this.throughLabel = this.label(this.markThroughTarget).textContent
  }

  disconnect() {
    this.cancelPress()
  }

  toggle(event) {
    const button = event.currentTarget
    const row = button.closest(ROW)
    const justClosed = performance.now() - (this.closedAt ?? -Infinity) < REOPEN_GUARD_MS
    if (justClosed && this.rowId === row.id) return

    button.focus({ preventScroll: true })
    this.open(row, button)
  }

  closed() {
    this.closedAt = performance.now()
    const row = this.row
    row?.removeAttribute("data-row-menu-open")
    row?.querySelector("[data-row-menu-button]")?.setAttribute("aria-expanded", "false")
  }

  press(event) {
    if (event.pointerType !== "touch" || !event.isPrimary) return
    const row = event.target.closest(ROW)
    if (!row?.querySelector("[data-row-menu-button]") || event.target.closest(TOGGLE)) return

    this.cancelPress()
    const { clientX: x, clientY: y } = event
    const move = (moveEvent) => {
      if (Math.hypot(moveEvent.clientX - x, moveEvent.clientY - y) > MOVE_TOLERANCE_PX) this.cancelPress()
    }
    const up = () => {
      this.cancelPress()
      if (this.pressFired) this.swallowNextClick()
    }
    this.pressFired = false
    this.pressTimer = setTimeout(() => {
      this.pressFired = true
      this.open(row, null)
    }, LONG_PRESS_MS)
    this.pressCleanup = () => {
      window.removeEventListener("pointermove", move)
      window.removeEventListener("pointerup", up)
      window.removeEventListener("pointercancel", up)
    }
    window.addEventListener("pointermove", move)
    window.addEventListener("pointerup", up)
    window.addEventListener("pointercancel", up)
  }

  // Long-press on a link would show the browser's link menu over the sheet.
  contextMenu(event) {
    if (this.pressTimer || this.pressFired) event.preventDefault()
  }

  toggleRead() {
    this.row?.querySelector(TOGGLE)?.requestSubmit()
  }

  async markThrough() {
    const row = this.row
    if (!row) return

    const body = this.rowIdsBody()
    body.set("chapter_id", row.dataset.chapterId)
    try {
      const reply = await this.send("POST", body)
      if (!reply.undo) return

      showUndoToast(reply.message, {
        undoLabel: this.copy.undo,
        icon: "bulk",
        onUndo: () => this.undoThrough(reply.undo),
      })
    } catch {
      showErrorMessage(this.copy.toggle_failed)
    }
  }

  async undoThrough(token) {
    const body = this.rowIdsBody()
    body.set("undo", token)
    try {
      await this.send("DELETE", body)
    } catch {
      showErrorMessage(this.copy.toggle_failed)
    }
  }

  // private

  open(row, button) {
    const sheet = this.sheet
    if (!sheet) return
    if (sheet.opened) sheet.close({ restoreFocus: false, immediate: true })

    this.rowId = row.id
    this.fill(row)
    this.place(button ?? row)
    row.setAttribute("data-row-menu-open", "")
    button?.setAttribute("aria-expanded", "true")
    sheet.open()
  }

  fill(row) {
    const read = row.querySelector(TOGGLE)?.dataset.readToggleReadValue === "true"
    const range = row.dataset.readThrough
    this.sheetTarget.querySelector("#chapter-row-menu-title").textContent = row.dataset.chapterTitle
    this.show(this.markReadTarget, !read)
    this.show(this.markThroughTarget, !read && Boolean(range))
    this.show(this.markUnreadTarget, read)
    if (range) this.label(this.markThroughTarget).textContent = this.throughLabel.replace("{range}", range)
  }

  // Hidden items are disabled too, so the sheet's focus handling skips them.
  show(item, visible) {
    item.hidden = !visible
    item.disabled = !visible
  }

  // From md up the menu drops from the anchor's bottom-right corner, under the ⋮.
  place(target) {
    const scope = this.element.getBoundingClientRect()
    const rect = target.getBoundingClientRect()
    this.anchorTarget.style.top = `${rect.bottom - scope.top}px`
    this.anchorTarget.style.left = `${rect.right - scope.left}px`
    this.anchorTarget.style.right = "auto"
  }

  cancelPress() {
    clearTimeout(this.pressTimer)
    this.pressTimer = null
    this.pressCleanup?.()
    this.pressCleanup = null
  }

  // Some browsers still send a click after a long-press; it would follow the row link or hit the sheet's scrim.
  swallowNextClick() {
    const swallow = (event) => {
      event.preventDefault()
      event.stopPropagation()
    }
    window.addEventListener("click", swallow, { capture: true, once: true })
    setTimeout(() => window.removeEventListener("click", swallow, { capture: true }), REOPEN_GUARD_MS)
    this.pressFired = false
  }

  rowIdsBody() {
    const body = new FormData()
    this.element.querySelectorAll(ROW).forEach((row) => body.append("row_ids[]", row.dataset.chapterId))
    return body
  }

  async send(method, body) {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const response = await fetch(this.urlValue, {
      method,
      body,
      credentials: "same-origin",
      headers: { Accept: "application/json", ...(token && { "X-CSRF-Token": token }) },
    })
    if (!response.ok || response.redirected) throw new Error(`read through failed: ${response.status}`)

    const reply = await response.json()
    Turbo.renderStreamMessage(reply.streams)
    Turbo.cache.clear()
    return reply
  }

  label(item) {
    return item.querySelector("span.flex-1")
  }

  get row() {
    return this.rowId ? document.getElementById(this.rowId) : null
  }

  get sheet() {
    return this.application.getControllerForElementAndIdentifier(this.sheetTarget, "bottom-sheet")
  }

  get copy() {
    const kit = this.element.querySelector("[data-read-toggle-kit]")
    return kit ? JSON.parse(kit.dataset.copy) : {}
  }
}
