import { Controller } from "@hotwired/stimulus"
import { applyTurboStream, fetchTurboStream } from "translation_requests/http"
import { showErrorMessage } from "translation_requests/notifications"

export default class extends Controller {
  static values = {
    currentPage: { type: Number, default: 1 }
  }

  disconnect() {
    this.abortListReload()
  }

  closeDropdowns(event) {
    if (event.target.closest('[data-translation-request-card-dropdown]')) return

    document.querySelectorAll('[data-translation-request-card-target="assignmentDropdown"]').forEach((element) => {
      element.classList.add('hidden')
    })
  }

  handleDeleted(event) {
    if (event.detail.isNewest) {
      window.location.reload()
      return
    }

    this.reloadList()
  }

  async reloadList() {
    const page = this.currentPageFromDom()

    this.abortListReload()
    this.listReloadAbortController = new AbortController()
    const { signal } = this.listReloadAbortController

    try {
      const html = await fetchTurboStream(`/translate?page=${page}`, { signal })
      const applied = applyTurboStream(html)

      if (!applied) return

      const requestCards = document.getElementById('requests-container')?.querySelectorAll('[data-controller~="translation-request-card"]')
      if (requestCards?.length === 0 && page > 1) {
        const previousPageHtml = await fetchTurboStream(`/translate?page=${page - 1}`, { signal })
        applyTurboStream(previousPageHtml)
      }
    } catch (error) {
      if (error.name === 'AbortError') return

      showErrorMessage('Сталася помилка при оновленні списку. Спробуйте ще раз.')
    } finally {
      this.listReloadAbortController = null
    }
  }

  abortListReload() {
    if (!this.listReloadAbortController) return

    this.listReloadAbortController.abort()
    this.listReloadAbortController = null
  }

  currentPageFromDom() {
    const marker = document.querySelector('[data-translation-requests-page-page]')
    if (marker) return parseInt(marker.dataset.translationRequestsPagePage, 10)

    return this.currentPageValue
  }
}
