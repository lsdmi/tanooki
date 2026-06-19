import { Controller } from "@hotwired/stimulus"

/** Expand/collapse inline TinyMCE note tooltips in chapter and tale content. */
export default class extends Controller {
  static values = { scrollDelay: { type: Number, default: 100 } }

  disconnect() {
    if (this._scrollTimeout) {
      clearTimeout(this._scrollTimeout)
      this._scrollTimeout = null
    }
    this.closeAllNotes()
  }

  toggle(event) {
    const reference = event.target.closest(".note-reference")
    if (!reference || !this.element.contains(reference)) return

    event.preventDefault()
    event.stopPropagation()

    const existingNote = reference.parentNode.querySelector(".note-content")
    if (existingNote) {
      existingNote.remove()
      return
    }

    this.closeAllNotes()

    const noteText = reference.getAttribute("data-note")
    const noteContent = document.createElement("div")
    noteContent.className = "note-content show"
    noteContent.textContent = noteText

    const parent = reference.parentNode
    const nextSibling = reference.nextSibling
    if (nextSibling) {
      parent.insertBefore(noteContent, nextSibling)
    } else {
      parent.appendChild(noteContent)
    }

    this._scrollTimeout = setTimeout(() => {
      noteContent.scrollIntoView({ behavior: "smooth", block: "nearest" })
      this._scrollTimeout = null
    }, this.scrollDelayValue)
  }

  closeAllNotes() {
    this.element.querySelectorAll(".note-content").forEach((content) => content.remove())
  }
}
