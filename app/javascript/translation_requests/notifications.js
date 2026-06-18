const TYPE_CLASSES = {
  success: 'bg-green-100 dark:bg-green-900/30 border border-green-200 dark:border-green-800 text-green-800 dark:text-green-200',
  error: 'bg-red-100 dark:bg-red-900/30 border border-red-200 dark:border-red-800 text-red-800 dark:text-red-200'
}

const ICONS = {
  success: `<svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
  </svg>`,
  error: `<svg class="w-5 h-5 text-red-600 dark:text-red-400" fill="currentColor" viewBox="0 0 20 20">
    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
  </svg>`
}

export function showSuccessMessage(message) {
  showNotification(message, 'success')
}

export function showErrorMessage(message) {
  showNotification(message, 'error')
}

function showNotification(message, type = 'success') {
  if (!message) return

  const existingNotifications = document.querySelectorAll('.notification-toast')
  const topOffset = 16 + (existingNotifications.length * 80)

  const notification = document.createElement('div')
  notification.classList.add('notification-toast')
  notification.className = `notification-toast fixed right-4 px-4 py-3 rounded-lg shadow-lg z-50 flex items-center gap-3 max-w-sm transform transition-all duration-300 ease-in-out ${TYPE_CLASSES[type] || TYPE_CLASSES.success}`
  notification.style.top = `${topOffset}px`

  const icon = document.createElement('div')
  icon.className = 'flex-shrink-0'
  icon.innerHTML = ICONS[type] || ICONS.success

  const messageText = document.createElement('div')
  messageText.className = 'text-sm font-medium flex-1'
  messageText.textContent = message

  const closeButton = document.createElement('button')
  closeButton.type = 'button'
  closeButton.className = 'flex-shrink-0 ml-2 text-current opacity-70 hover:opacity-100 transition-opacity duration-200'
  closeButton.innerHTML = `<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
  </svg>`

  notification.append(icon, messageText, closeButton)
  notification.style.transform = 'translateX(100%)'
  notification.style.opacity = '0'
  document.body.appendChild(notification)

  requestAnimationFrame(() => {
    notification.style.transform = 'translateX(0)'
    notification.style.opacity = '1'
  })

  const removeNotification = () => {
    notification.style.transform = 'translateX(100%)'
    notification.style.opacity = '0'
    setTimeout(() => notification.remove(), 300)
  }

  closeButton.addEventListener('click', removeNotification)
  setTimeout(removeNotification, type === 'error' ? 5000 : 3000)
}
