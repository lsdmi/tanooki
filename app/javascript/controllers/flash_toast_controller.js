import { Controller } from '@hotwired/stimulus'
import { showFlashToast } from 'flash_toast'

export default class extends Controller {
  static values = {
    type: { type: String, default: 'notice' },
    message: String
  }

  connect() {
    const message = this.messageValue?.trim()
    if (!message) return

    showFlashToast(message, this.typeValue)
    requestAnimationFrame(() => this.element.remove())
  }
}
