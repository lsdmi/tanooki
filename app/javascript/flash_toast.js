import Swal from 'sweetalert2'

const pendingToasts = []

const TOAST_POPUP_BASE = [
  '!m-3 !box-border !flex !w-auto !max-w-sm !items-center !gap-3 max-sm:!max-w-[calc(100vw-1.5rem)]',
  '!rounded-lg !border !border-l-[3px] !py-2.5 !pl-3.5 !pr-2 !font-sans',
  '!bg-main/95 !text-fg !shadow-md !shadow-slate-900/10 !backdrop-blur-md',
  'dark:!shadow-black/40',
  '!border-line'
].join(' ')

const TOAST_TITLE_CLASSES = [
  '!m-0 !flex-1 !p-0 !text-left !text-sm !font-medium !leading-snug !tracking-wide',
  '!text-fg'
].join(' ')

const TOAST_CLOSE_CLASSES = [
  '!order-last !ml-auto !mr-0 !mt-0 !mb-0 !flex !h-7 !w-7 !shrink-0 !items-center !justify-center !rounded-md !border-0',
  '!bg-transparent !text-lg !font-normal !text-fg-subtle',
  'hover:!bg-surface hover:!text-fg-secondary'
].join(' ')

const NOTICE_VARIANT = {
  popup: '!border-l-brand',
  timerBar: '!bg-brand',
  timer: 3000
}

const TOAST_VARIANTS = {
  notice: NOTICE_VARIANT,
  success: NOTICE_VARIANT,
  alert: {
    popup: '!border-l-amber-500 dark:!border-l-amber-400',
    timerBar: '!bg-amber-500 dark:!bg-amber-400',
    timer: 5000
  },
  error: {
    popup: '!border-l-status-danger-solid',
    timerBar: '!bg-status-danger-solid',
    timer: 5000
  }
}

const Toast = Swal.mixin({
  toast: true,
  position: 'top-end',
  showConfirmButton: false,
  showCloseButton: true,
  timerProgressBar: true,
  didOpen: (toast) => {
    toast.addEventListener('mouseenter', Swal.stopTimer)
    toast.addEventListener('mouseleave', Swal.resumeTimer)
  },
})

export function showFlashToast(message, type = 'notice') {
  const text = (message || '').trim()
  if (!text) return

  if (modalIsOpen()) {
    pendingToasts.push({ text, type })
    return
  }

  fireToast(text, type)
}

export function showSuccessMessage(message) {
  showFlashToast(message, 'success')
}

export function showErrorMessage(message) {
  showFlashToast(message, 'error')
}

export function flushPendingFlashToasts() {
  if (modalIsOpen() || pendingToasts.length === 0) return

  const next = pendingToasts.shift()
  fireToast(next.text, next.type)
}

function fireToast(text, type) {
  const variant = TOAST_VARIANTS[type] || NOTICE_VARIANT

  Toast.fire({
    title: text,
    timer: variant.timer,
    customClass: {
      popup: `${TOAST_POPUP_BASE} ${variant.popup}`,
      title: TOAST_TITLE_CLASSES,
      closeButton: TOAST_CLOSE_CLASSES,
      timerProgressBar: variant.timerBar,
    },
  })
}

const UNDO_ICON_PATHS = {
  read: ['M20 6 9 17l-5-5'],
  unread: ['M9 14 4 9l5-5', 'M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5a5.5 5.5 0 0 1-5.5 5.5H11'],
  bulk: ['M18 6 7 17l-5-5', 'm22 10-7.5 7.5L13 16']
}

const UNDO_TOAST_HOST_CLASSES = [
  'pointer-events-none fixed inset-x-4 z-[80] mx-auto max-w-[440px]',
  'bottom-[max(1rem,env(safe-area-inset-bottom))]'
].join(' ')

const UNDO_TOAST_CLASSES = [
  'pointer-events-auto flex items-center gap-4 rounded-xl bg-invert py-3 pl-4 pr-3 text-fg-on-invert shadow-toast',
  'translate-y-2 opacity-0 transition duration-200 ease-out'
].join(' ')

const UNDO_BUTTON_CLASSES = [
  'shrink-0 rounded-md px-2 py-1 text-sm font-medium text-fg-on-invert-action hover:underline',
  'focus:outline-none focus-visible:ring-2 focus-visible:ring-fg-on-invert-action'
].join(' ')

let activeUndoToast = null

/**
 * Bottom toast with an undo action (Figma «Undo toast», 10161:12071). Only one is shown at a time.
 * `undoLabel` comes from the server (`undo_toast.undo`); `icon` is read / unread / bulk.
 * Returns `{ dismiss }`, or null when there is nothing to show.
 */
export function showUndoToast(message, { onUndo, undoLabel, icon = 'read', timeout = 5000 } = {}) {
  const text = (message || '').trim()
  if (!text || !undoLabel) return null

  activeUndoToast?.dismiss({ immediate: true })

  const host = document.createElement('div')
  host.className = UNDO_TOAST_HOST_CLASSES
  host.innerHTML = `<div class="${UNDO_TOAST_CLASSES}" role="status" aria-live="polite">${undoIconSvg(icon)}<p class="min-w-0 flex-1 text-sm"></p><button type="button" class="${UNDO_BUTTON_CLASSES}"></button></div>`
  const toast = host.firstElementChild
  toast.querySelector('p').textContent = text
  const button = toast.querySelector('button')
  button.textContent = undoLabel

  let remaining = timeout
  let startedAt = 0
  let timer = null
  const pause = () => {
    if (!timer) return
    clearTimeout(timer)
    timer = null
    remaining -= Date.now() - startedAt
  }
  const resume = () => {
    if (timer || toast.matches(':hover, :focus-within')) return
    startedAt = Date.now()
    timer = setTimeout(() => handle.dismiss(), Math.max(remaining, 0))
  }

  const handle = {
    dismiss({ immediate = false } = {}) {
      if (activeUndoToast === handle) activeUndoToast = null
      clearTimeout(timer)
      document.removeEventListener('turbo:before-cache', onBeforeCache)
      if (immediate) {
        host.remove()
        return
      }
      toast.classList.add('translate-y-2', 'opacity-0')
      setTimeout(() => host.remove(), 200)
    }
  }
  const onBeforeCache = () => handle.dismiss({ immediate: true })

  button.addEventListener('click', () => {
    handle.dismiss()
    onUndo?.()
  })
  toast.addEventListener('mouseenter', pause)
  toast.addEventListener('mouseleave', resume)
  toast.addEventListener('focusin', pause)
  toast.addEventListener('focusout', () => setTimeout(resume))
  document.addEventListener('turbo:before-cache', onBeforeCache)

  document.body.appendChild(host)
  requestAnimationFrame(() => toast.classList.remove('translate-y-2', 'opacity-0'))
  activeUndoToast = handle
  resume()
  return handle
}

function undoIconSvg(icon) {
  const paths = (UNDO_ICON_PATHS[icon] || UNDO_ICON_PATHS.read).map((d) => `<path d="${d}" />`).join('')
  return `<svg class="size-5 shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths}</svg>`
}

function modalIsOpen() {
  const popup = Swal.getPopup()
  return Boolean(popup && !popup.classList.contains('swal2-toast'))
}
