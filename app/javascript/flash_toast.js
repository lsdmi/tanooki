import Swal from 'sweetalert2'

const pendingToasts = []

const TOAST_POPUP_BASE = [
  '!m-3 !box-border !flex !w-auto !max-w-sm !items-center !gap-3 max-sm:!max-w-[calc(100vw-1.5rem)]',
  '!rounded-lg !border !border-l-[3px] !py-2.5 !pl-3.5 !pr-2 !font-sans',
  '!bg-white/95 !text-stone-800 !shadow-md !shadow-stone-900/10 !backdrop-blur-md',
  'dark:!bg-gray-900/95 dark:!text-gray-100 dark:!shadow-black/40',
  '!border-stone-200 dark:!border-gray-700'
].join(' ')

const TOAST_TITLE_CLASSES = [
  '!m-0 !flex-1 !p-0 !text-left !text-sm !font-medium !leading-snug !tracking-wide',
  '!text-stone-800 dark:!text-gray-100'
].join(' ')

const TOAST_CLOSE_CLASSES = [
  '!order-last !ml-auto !mr-0 !mt-0 !mb-0 !flex !h-7 !w-7 !shrink-0 !items-center !justify-center !rounded-md !border-0',
  '!bg-transparent !text-lg !font-normal !text-stone-400',
  'hover:!bg-stone-100 hover:!text-stone-700',
  'dark:!text-gray-500 dark:hover:!bg-gray-800 dark:hover:!text-gray-200'
].join(' ')

const NOTICE_VARIANT = {
  popup: '!border-l-cyan-700 dark:!border-l-rose-500',
  timerBar: '!bg-cyan-700 dark:!bg-rose-500',
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
    popup: '!border-l-red-600 dark:!border-l-red-400',
    timerBar: '!bg-red-600 dark:!bg-red-400',
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

function modalIsOpen() {
  const popup = Swal.getPopup()
  return Boolean(popup && !popup.classList.contains('swal2-toast'))
}
