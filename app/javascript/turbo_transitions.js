import Swal from 'sweetalert2'

// Turbo Drive UX: cross-fade on full body swaps (not morph), prefetch guards on slow/save-data networks.

document.addEventListener('turbo:before-visit', () => {
  document.documentElement.classList.add('turbo-transitioning')
})

document.addEventListener('turbo:render', (event) => {
  if (event.detail?.renderMethod === 'morph') return
  document.documentElement.classList.remove('turbo-transitioning')
})

document.addEventListener('turbo:load', () => {
  document.documentElement.classList.remove('turbo-transitioning')
})

document.addEventListener('turbo:before-prefetch', (event) => {
  const conn = navigator.connection
  if (!conn) return

  if (conn.saveData) {
    event.preventDefault()
    return
  }

  const slow = ['slow-2g', '2g', '3g'].includes(conn.effectiveType)
  if (slow) event.preventDefault()
})

function cleanupBeforeTurboCache() {
  document.querySelectorAll('.flatpickr-calendar').forEach((el) => el.remove())
  document.querySelectorAll('.note-content').forEach((el) => el.remove())
  document.body.classList.remove('overflow-hidden')
  document.documentElement.classList.remove('overflow-hidden')

  if (Swal.isVisible?.()) Swal.close()

  if (typeof tinymce !== 'undefined') {
    tinymce.remove()
    document.querySelectorAll('.tox-tinymce').forEach((el) => el.remove())
  }

  document.querySelectorAll('[data-mode-toggler-bound="true"]').forEach((btn) => {
    delete btn.dataset.modeTogglerBound
  })
}

document.addEventListener('turbo:before-cache', cleanupBeforeTurboCache)
