import Swal from 'sweetalert2'
import { turboCacheHooks } from 'turbo_cache_hooks'

// Turbo Drive UX: cross-fade on full body swaps (not morph), prefetch guards on slow/save-data networks.

function progressBarElement() {
  return document.querySelector('.turbo-progress-bar')
}

function setProgressBarHidden(hidden) {
  progressBarElement()?.classList.toggle('turbo-progress-bar--hidden', hidden)
}

document.addEventListener('turbo:before-visit', () => {
  document.documentElement.classList.add('turbo-transitioning')
  setProgressBarHidden(false)
})

document.addEventListener('turbo:before-render', (event) => {
  if (event.detail?.renderMethod === 'morph') {
    setProgressBarHidden(true)
  }
})

document.addEventListener('turbo:morph', () => {
  setProgressBarHidden(true)
})

document.addEventListener('turbo:load', () => {
  setProgressBarHidden(false)
  document.documentElement.classList.remove('turbo-transitioning')
})

document.addEventListener('turbo:render', (event) => {
  if (event.detail?.renderMethod === 'morph') return
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

function removeFlatpickrCalendarsFromDom() {
  document.querySelectorAll('.flatpickr-calendar').forEach((el) => el.remove())
}

function closeFlowbiteDropdownsAndModals() {
  document.querySelectorAll("[data-dropdown-toggle][aria-expanded='true']").forEach((toggle) => {
    const menuId = toggle.getAttribute('data-dropdown-toggle')
    const menu = menuId ? document.getElementById(menuId) : null

    toggle.setAttribute('aria-expanded', 'false')
    if (menu) {
      menu.classList.add('hidden')
      menu.classList.remove('block')
    }
  })

  document.querySelectorAll("[data-modal-toggle][aria-expanded='true']").forEach((toggle) => {
    const modalId = toggle.getAttribute('data-modal-target') || toggle.getAttribute('data-modal-toggle')
    const modal = modalId ? document.getElementById(modalId) : null

    toggle.setAttribute('aria-expanded', 'false')
    if (modal) {
      modal.classList.add('hidden')
      modal.classList.remove('flex')
      modal.setAttribute('aria-hidden', 'true')
    }
  })

  // Flowbite appends a body-level backdrop when a modal opens.
  document.querySelectorAll('body > div.fixed.inset-0').forEach((el) => {
    if (el.classList.contains('bg-gray-900/50') || el.classList.contains('dark:bg-gray-900/80')) {
      el.remove()
    }
  })
}

function resetReaderDrawersForCache() {
  document
    .querySelectorAll(
      '[data-chapter-drawer-target="backdrop"], [data-comments-drawer-target="backdrop"], [data-reader-settings-target="backdrop"]'
    )
    .forEach((el) => {
      el.classList.add('opacity-0', 'pointer-events-none')
      el.classList.remove('opacity-100', 'pointer-events-auto')
      el.setAttribute('aria-hidden', 'true')
    })

  document
    .querySelectorAll(
      '[data-chapter-drawer-target="panel"], [data-comments-drawer-target="panel"], [data-reader-settings-target="panel"]'
    )
    .forEach((el) => {
      el.classList.add('translate-x-full')
      el.classList.remove('translate-x-0')
    })

  document
    .querySelectorAll(
      '[data-chapter-drawer-target="trigger"], [data-comments-drawer-target="trigger"], [data-reader-settings-target="trigger"]'
    )
    .forEach((el) => {
      el.setAttribute('aria-expanded', 'false')
    })

  document.querySelectorAll('[data-reader-ad-drawer-target="backdrop"]').forEach((el) => {
    el.classList.add('opacity-0', 'pointer-events-none')
    el.classList.remove('opacity-100', 'pointer-events-auto')
    el.setAttribute('aria-hidden', 'true')
  })

  document.querySelectorAll('[data-reader-ad-drawer-target="panel"]').forEach((el) => {
    el.classList.add('opacity-0', 'invisible', 'pointer-events-none')
    el.classList.remove('opacity-100', 'visible', 'pointer-events-auto')
  })
}

function cleanupBeforeTurboCache() {
  removeFlatpickrCalendarsFromDom()
  closeFlowbiteDropdownsAndModals()
  resetReaderDrawersForCache()
  turboCacheHooks.readerPreferences?.()

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

// Flatpickr portals the calendar to <body>. On failed submits Turbo often updates without a full reload,
// so `before-cache` alone misses — clean up on every relevant Turbo phase.
;['turbo:before-render', 'turbo:before-stream-render'].forEach((name) => {
  document.addEventListener(name, removeFlatpickrCalendarsFromDom)
})
