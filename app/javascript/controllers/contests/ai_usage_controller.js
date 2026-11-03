import { Controller } from "@hotwired/stimulus"

// Reveals the optional AI note when usage is assist or substantial.
export default class extends Controller {
  static targets = ["note"]
  static values = { reveal: { type: Array, default: ["assist", "substantial"] } }

  connect() {
    this.sync()
  }

  sync() {
    if (!this.hasNoteTarget) return
    const selected = this.element.querySelector('input[name="fiction[ai_usage]"]:checked, input[name="participation[ai_usage]"]:checked')
    const show = selected && this.revealValue.includes(selected.value)
    this.noteTarget.hidden = !show
    this.noteTarget.querySelectorAll("textarea, input").forEach((el) => {
      el.disabled = !show
    })
  }
}
