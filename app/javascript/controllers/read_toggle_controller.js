import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { showErrorMessage, showUndoToast } from "flash_toast"

const TOGGLE = "form[data-controller~='read-toggle']"
const queues = new Map()
const kits = new WeakMap()

/**
 * Status circle toggle (Figma «Read toggle» 10161:12003) on the fiction page list and in the reader drawer.
 * A click swaps the icon on every row of that chapter and bumps the read counts at once, shows the undo toast, then
 * posts. The Turbo Stream reply re-renders the rows and counts from the server; a failed request puts the old state
 * back. Undo sends the opposite verb for the same row, found again by id because the reply replaced it. Requests for
 * one row run in order, so a quick undo cannot overtake the toggle it undoes.
 * Shared strings and icons come from the list's `[data-read-toggle-kit]` (JS has no i18n).
 */
export default class extends Controller {
  static targets = ["icon", "tip"]
  static values = { read: Boolean, number: String }

  submit(event) {
    event.preventDefault()
    const row = this.element.closest("li[id]")
    const scope = this.element.closest("[data-read-toggle-scope]")
    if (!row || !scope) return

    const read = !this.readValue
    const { copy } = readKit(scope)
    const message = copy[read ? "marked_read" : "marked_unread"].replace("{number}", this.numberValue)
    const toast = showUndoToast(message, {
      undoLabel: copy.undo,
      icon: read ? "read" : "unread",
      onUndo: () => toggle(row.id, !read),
    })
    toggle(row.id, read, toast)
  }
}

function toggle(rowId, read, toast = null) {
  const form = document.getElementById(rowId)?.querySelector(TOGGLE)
  const scope = form?.closest("[data-read-toggle-scope]")
  if (!scope) return

  const kit = readKit(scope)
  const revert = applyState(scope, form, read, kit)
  const body = new FormData(form)
  body.delete("_method")
  if (!read) body.set("_method", "delete")

  const next = (queues.get(rowId) ?? Promise.resolve())
    .then(() => send(form.action, body))
    .catch(() => {
      revert()
      toast?.dismiss({ immediate: true })
      showErrorMessage(kit.copy.toggle_failed)
    })
  queues.set(rowId, next)
  next.then(() => {
    if (queues.get(rowId) === next) queues.delete(rowId)
  })
}

async function send(url, body) {
  const token = document.querySelector("meta[name='csrf-token']")?.content
  const response = await fetch(url, {
    method: "POST",
    body,
    credentials: "same-origin",
    headers: { Accept: "text/vnd.turbo-stream.html", ...(token && { "X-CSRF-Token": token }) },
  })
  if (!response.ok || response.redirected) throw new Error(`read toggle failed: ${response.status}`)

  Turbo.renderStreamMessage(await response.text())
  Turbo.cache.clear()
}

// Returns a function that restores what it changed.
function applyState(scope, form, read, kit) {
  const row = form.closest("li[data-chapter-key]")
  const changed = form.dataset.readToggleReadValue !== String(read)
  const rows = scope.querySelectorAll(`li[data-chapter-key="${CSS.escape(row.dataset.chapterKey)}"]`)
  const restores = Array.from(rows, (each) => swapToggle(each.querySelector(TOGGLE), read, kit))
  if (changed) restores.push(...counters(row).map((counter) => bump(counter, read ? 1 : -1)))
  return () => restores.forEach((restore) => restore())
}

function swapToggle(form, read, kit) {
  if (!form) return () => {}

  const button = form.querySelector("button")
  const icon = form.querySelector("[data-read-toggle-target='icon']")
  const tip = form.querySelector("[data-read-toggle-target='tip']")
  const before = [form.dataset.readToggleReadValue, icon.innerHTML, button.getAttribute("aria-label"), tip.textContent]
  const after = [
    String(read),
    kit.icons[read ? "read" : "unread"],
    kit.copy[read ? "mark_unread" : "mark_read"],
    kit.copy[read ? "mark_unread_tip" : "mark_read_tip"],
  ]
  const set = ([value, html, label, text]) => {
    form.dataset.readToggleReadValue = value
    icon.innerHTML = html
    button.setAttribute("aria-label", label)
    tip.textContent = text
  }
  set(after)
  return () => set(before)
}

// The row's group header and the tab header, when they show a read count (not before the first read).
function counters(row) {
  const group = row.closest(".accordion")?.querySelector(".accordion-header [data-read-progress]")
  const list = document.getElementById("chapter_list_progress")
  return [group, list?.matches("[data-read-progress]") ? list : null].filter(Boolean)
}

function bump(counter, delta) {
  const read = Number(counter.dataset.read) + delta
  if (read < 0 || read > Number(counter.dataset.total)) return () => {}

  setCount(counter, read)
  return () => setCount(counter, read - delta)
}

function setCount(counter, read) {
  const total = Number(counter.dataset.total)
  counter.dataset.read = read
  const text = counter.querySelector("[data-read-progress-text]")
  if (text) text.textContent = text.dataset.readProgressText.replace("{read}", read)
  const bar = counter.querySelector("[role='progressbar']")
  if (!bar) return

  bar.setAttribute("aria-valuenow", read)
  const fill = bar.firstElementChild?.firstElementChild
  if (fill) fill.style.width = `${total ? (read * 100) / total : 0}%`
}

function readKit(scope) {
  if (!kits.has(scope)) {
    const node = scope.querySelector("[data-read-toggle-kit]")
    const icon = (state) => node.querySelector(`template[data-icon='${state}']`).innerHTML
    kits.set(scope, { copy: JSON.parse(node.dataset.copy), icons: { read: icon("read"), unread: icon("unread") } })
  }
  return kits.get(scope)
}
