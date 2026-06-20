import { Controller } from '@hotwired/stimulus'
import Swal from 'sweetalert2'
import { Turbo } from '@hotwired/turbo-rails'

export default class extends Controller {
  static values = {
    message: String,
    description: String,
    url: String,
    tagId: String
  }

  async confirm(event) {
    event.preventDefault()
    event.stopPropagation()

    const message = this.messageValue
    const description = this.descriptionValue

    const swalOptions = {
      customClass: {
        container: 'swal-container',
        title: 'title',
        htmlContainer: 'htmlContainer',
        actions: 'actions',
        confirmButton: 'swal-button swal-confirm',
        cancelButton: 'swal-button',
      },
      text: description,
      showDenyButton: false,
      showCancelButton: true,
      confirmButtonText: 'Прибрати',
      cancelButtonText: 'Відмінити',
    }

    if (message) swalOptions.title = message

    const result = await Swal.fire(swalOptions)

    if (!result.isConfirmed || !this.hasUrlValue) return

    const response = await fetch(this.urlValue, {
      method: 'DELETE',
      headers: {
        'Content-Type': this.tagDeleteUsesJson() ? 'application/json' : 'application/turbo_stream',
        'X-CSRF-Token': this.csrfToken(),
      },
      credentials: 'include',
    })

    if (this.tagDeleteUsesJson()) {
      if (response.ok && this.hasTagIdValue) {
        document.getElementById(this.tagIdValue)?.remove()
      }
      return
    }

    const turboStream = await response.text()
    Turbo.renderStreamMessage(turboStream)
  }

  tagDeleteUsesJson() {
    return this.hasTagIdValue && this.tagIdValue !== ''
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
  }
}
