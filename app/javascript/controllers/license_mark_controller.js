import { Controller } from '@hotwired/stimulus'
import Swal from 'sweetalert2'

/** Fiction form license block: shows the source fields when checked, and confirms a first mark before submit. */
export default class extends Controller {
  static targets = ['checkbox', 'fields', 'confirmBody']
  static values = { marked: Boolean, title: String, accept: String, cancel: String }

  toggle() {
    this.fieldsTarget.hidden = !this.checkboxTarget.checked
  }

  async confirm(event) {
    const form = this.element.closest('form')
    if (event.target !== form || this.confirmed || !this.needsConfirm()) return

    event.preventDefault()
    const result = await Swal.fire({
      customClass: {
        container: 'swal-container',
        title: 'title',
        htmlContainer: 'htmlContainer',
        actions: 'actions',
        confirmButton: 'swal-button swal-confirm',
        cancelButton: 'swal-button',
      },
      title: this.titleValue,
      html: this.confirmBodyTarget.innerHTML,
      showCancelButton: true,
      focusCancel: true,
      confirmButtonText: this.acceptValue,
      cancelButtonText: this.cancelValue,
    })
    if (!result.isConfirmed) return

    this.confirmed = true
    form.requestSubmit(event.submitter)
  }

  needsConfirm() {
    return !this.markedValue && this.hasCheckboxTarget && this.checkboxTarget.checked
  }
}
