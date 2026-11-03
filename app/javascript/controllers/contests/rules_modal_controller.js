import { Controller } from "@hotwired/stimulus"

// Native <dialog> for contest rules on the submission screen.
export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event?.preventDefault()
    this.dialogTarget.showModal()
  }

  close(event) {
    event?.preventDefault()
    this.dialogTarget.close()
  }

  backdrop(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }
}
