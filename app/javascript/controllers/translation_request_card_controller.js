import { Controller } from "@hotwired/stimulus"
import { fetchJson, safeHttpUrl } from "translation_requests/http"
import { showErrorMessage, showSuccessMessage } from "translation_requests/notifications"

export default class extends Controller {
  static targets = [
    "viewMode",
    "editMode",
    "title",
    "authorRow",
    "authorValue",
    "sourceRow",
    "sourceLink",
    "notes",
    "voteButton",
    "upvoteCount",
    "votesCount",
    "assignmentDropdown",
    "assignmentAssigned",
    "assignmentAvailable",
    "scanlatorTitle"
  ]

  static values = {
    requestId: Number,
    voted: Boolean
  }

  vote() {
    this.voteButtonTarget.disabled = true

    fetchJson(`/translate/${this.requestIdValue}/votes`, { method: 'POST' })
      .then(({ data }) => {
        if (data.error) {
          showErrorMessage(data.error)
          return
        }

        this.upvoteCountTargets.forEach((element) => {
          element.textContent = data.votes_count
        })
        this.votesCountTargets.forEach((element) => {
          element.textContent = data.votes_count
        })
        this.votedValue = data.user_voted
        this.updateVoteButtonStyles()
      })
      .catch(() => showErrorMessage('Сталася помилка при голосуванні. Спробуйте ще раз.'))
      .finally(() => {
        this.voteButtonTarget.disabled = false
      })
  }

  updateVoteButtonStyles() {
    const votedClasses = this.voteButtonTarget.dataset.votedClass
    const defaultClasses = this.voteButtonTarget.dataset.defaultClass

    this.voteButtonTarget.className = this.votedValue ? votedClasses : defaultClasses
  }

  toggleEdit() {
    this.viewModeTarget.classList.add('hidden')
    this.editModeTarget.classList.remove('hidden')
  }

  cancelEdit() {
    this.editModeTarget.classList.add('hidden')
    this.viewModeTarget.classList.remove('hidden')
  }

  async saveEdit(event) {
    const saveButton = event.currentTarget
    const originalText = saveButton.textContent

    saveButton.disabled = true
    saveButton.textContent = 'Збереження...'

    try {
      const { data } = await fetchJson(`/translate/${this.requestIdValue}`, {
        method: 'PATCH',
        body: {
          translation_request: {
            title: this.editField('title').value,
            author: this.editField('author').value,
            source_url: this.editField('sourceUrl').value,
            notes: this.editField('notes').value
          }
        }
      })

      if (data.success) {
        this.updateView(
          this.editField('title').value,
          this.editField('author').value,
          this.editField('sourceUrl').value,
          this.editField('notes').value
        )
        this.cancelEdit()
        showSuccessMessage(data.message)
      } else if (data.errors?.length) {
        showErrorMessage(data.errors.join(', '))
      } else {
        showErrorMessage('Сталася помилка при оновленні запиту.')
      }
    } catch {
      showErrorMessage('Сталася помилка при оновленні запиту. Спробуйте ще раз.')
    } finally {
      saveButton.disabled = false
      saveButton.textContent = originalText
    }
  }

  editField(name) {
    return this.editModeTarget.querySelector(`[data-translation-request-card-field="${name}"]`)
  }

  updateView(title, author, sourceUrl, notes) {
    this.titleTarget.textContent = title

    if (this.hasAuthorRowTarget) {
      if (author?.trim()) {
        this.authorValueTarget.textContent = author
        this.authorRowTarget.classList.remove('hidden')
      } else {
        this.authorRowTarget.classList.add('hidden')
      }
    }

    if (this.hasSourceRowTarget) {
      const href = safeHttpUrl(sourceUrl)
      if (href) {
        this.sourceLinkTarget.href = href
        this.sourceRowTarget.classList.remove('hidden')
      } else {
        this.sourceLinkTarget.removeAttribute('href')
        this.sourceRowTarget.classList.add('hidden')
      }
    }

    if (this.hasNotesTarget) {
      this.notesTarget.textContent = notes
    }
  }

  async delete() {
    this.element.style.opacity = '0.5'
    this.element.style.pointerEvents = 'none'

    const isNewest = Boolean(document.getElementById('newest-request-section')?.contains(this.element))

    try {
      const { data } = await fetchJson(`/translate/${this.requestIdValue}`, { method: 'DELETE' })

      if (data.success) {
        showSuccessMessage(data.message)
        this.dispatch('deleted', { detail: { isNewest }, bubbles: true })
        return
      }

      this.resetCardInteraction()
      showErrorMessage(data.error || 'Сталася помилка при видаленні запиту.')
    } catch {
      this.resetCardInteraction()
      showErrorMessage('Сталася помилка при видаленні запиту. Спробуйте ще раз.')
    }
  }

  resetCardInteraction() {
    this.element.style.opacity = '1'
    this.element.style.pointerEvents = 'auto'
  }

  toggleAssignmentDropdown(event) {
    event.stopPropagation()
    this.assignmentDropdownTarget.classList.toggle('hidden')
    this.closeOtherDropdowns()
  }

  closeOtherDropdowns() {
    document.querySelectorAll('[data-translation-request-card-target="assignmentDropdown"]').forEach((element) => {
      if (element !== this.assignmentDropdownTarget) {
        element.classList.add('hidden')
      }
    })
  }

  assign(event) {
    const scanlatorId = event.params.scanlatorId
    this.assignmentDropdownTarget.classList.add('hidden')

    fetchJson(`/translate/${this.requestIdValue}/assign`, {
      method: 'PATCH',
      body: { scanlator_id: scanlatorId }
    })
      .then(({ data }) => {
        if (data.error) {
          showErrorMessage(data.error)
          return
        }

        if (data.success) {
          this.showAssigned(data.scanlator_title)
          showSuccessMessage(data.message)
        }
      })
      .catch(() => showErrorMessage('Сталася помилка при призначенні запиту. Спробуйте ще раз.'))
  }

  unassign() {
    fetchJson(`/translate/${this.requestIdValue}/unassign`, { method: 'DELETE' })
      .then(({ data }) => {
        if (data.error) {
          showErrorMessage(data.error)
          return
        }

        if (data.success) {
          this.showAvailable()
          showSuccessMessage(data.message)
        }
      })
      .catch(() => showErrorMessage('Сталася помилка при відкликанні запиту. Спробуйте ще раз.'))
  }

  showAssigned(scanlatorTitle) {
    if (this.hasScanlatorTitleTarget) {
      this.scanlatorTitleTarget.textContent = scanlatorTitle
    }
    this.assignmentAssignedTarget.classList.remove('hidden')
    this.assignmentAvailableTarget.classList.add('hidden')
  }

  showAvailable() {
    this.assignmentAssignedTarget.classList.add('hidden')
    this.assignmentAvailableTarget.classList.remove('hidden')
  }
}
