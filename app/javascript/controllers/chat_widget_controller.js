import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["toggle", "window", "close", "messages", "input", "send", "resizeHandleTopLeft"]
  static turboNavigationPending = false
  static turboNavigationBound = false

  connect() {
    this.bindTurboNavigationTracking()

    this.isSignedIn = this.element.querySelector('[data-chat-widget-target="input"]') !== null

    this.restoreNavigationState()
    if (!this.initialized) {
      this.initialized = this.hasExistingMessages()
    }
    this.isLoading = false

    if (this.initialized) {
      this.setupFullEventListeners()
      this.connectSubscription()
    }

    this.setupBasicEventListeners()

    if (this.hasResizeHandleTopLeftTarget && this.hasWindowTarget) {
      this.resizeHandleTopLeftTarget.addEventListener('mousedown', this.startResizeTopLeft)
    }
  }

  disconnect() {
    if (this.constructor.turboNavigationPending) {
      this.preserveNavigationState()
      if (this.subscription) {
        this.subscription.unsubscribe()
        this.subscription = null
      }
    } else {
      this.cleanup()
    }

    this.removeBasicEventListeners()
    this.removeFullEventListeners()

    if (this.hasResizeHandleTopLeftTarget) {
      this.resizeHandleTopLeftTarget.removeEventListener('mousedown', this.startResizeTopLeft)
    }
    this.removeResizeListeners()
  }

  static bindTurboNavigationTracking() {
    if (this.turboNavigationBound) return
    this.turboNavigationBound = true

    document.addEventListener("turbo:before-visit", () => {
      this.turboNavigationPending = true
    })

    document.addEventListener("turbo:load", () => {
      this.turboNavigationPending = false
    })
  }

  bindTurboNavigationTracking() {
    this.constructor.bindTurboNavigationTracking()
  }

  preserveNavigationState() {
    this.element._chatWidgetState = { initialized: this.initialized }
  }

  restoreNavigationState() {
    const preserved = this.element._chatWidgetState
    if (!preserved) return

    this.initialized = preserved.initialized
    delete this.element._chatWidgetState
  }

  hasExistingMessages() {
    return this.hasMessagesTarget && this.messagesTarget.querySelector("[data-message-id]") !== null
  }

  cleanup() {
    try {
      if (this.subscription) {
        this.subscription.unsubscribe()
        this.subscription = null
      }
      this.initialized = false
    } catch (error) {
      console.error("Error during cleanup:", error)
    }
  }

  setupBasicEventListeners() {
    try {
      this.boundHandleToggleClick = this.boundHandleToggleClick || (() => this.handleToggleClick())
      this.boundCloseChat = this.boundCloseChat || (() => this.closeChat())

      if (this.hasToggleTarget && this.toggleTarget) {
        this.toggleTarget.addEventListener('click', this.boundHandleToggleClick)
      }

      if (this.hasCloseTarget && this.closeTarget) {
        this.closeTarget.addEventListener('click', this.boundCloseChat)
      }
    } catch (error) {
      console.error("Error setting up basic event listeners:", error)
    }
  }

  removeBasicEventListeners() {
    if (this.hasToggleTarget && this.toggleTarget && this.boundHandleToggleClick) {
      this.toggleTarget.removeEventListener('click', this.boundHandleToggleClick)
    }

    if (this.hasCloseTarget && this.closeTarget && this.boundCloseChat) {
      this.closeTarget.removeEventListener('click', this.boundCloseChat)
    }
  }

  async handleToggleClick() {
    try {
      if (!this.initialized && !this.isLoading) {
        await this.initializeChat()
      }

      this.toggleChat()
    } catch (error) {
      console.error("Error handling toggle click:", error)
    }
  }

  async initializeChat() {
    try {
      if (this.initialized || this.isLoading) return

      this.isLoading = true
      this.showLoadingState()
      this.setupFullEventListeners()

      await this.loadRecentMessages()

      this.connectSubscription()
      this.initialized = true
    } catch (error) {
      console.error("Error initializing chat:", error)
      this.showLoadError()
    } finally {
      this.isLoading = false
    }
  }

  connectSubscription() {
    if (this.subscription) return

    this.subscription = consumer.subscriptions.create("ChatChannel", {
      received: (data) => {
        this.addMessage(data)
      }
    })
  }

  showLoadingState() {
    try {
      if (this.hasMessagesTarget && this.messagesTarget) {
        this.messagesTarget.innerHTML = `
          <div class="flex items-center justify-center h-full">
            <div class="flex items-center space-x-2 text-gray-500 dark:text-gray-400">
              <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-cyan-700 dark:border-rose-400"></div>
              <span class="text-sm">Завантаження чату...</span>
            </div>
          </div>
        `
      }
    } catch (error) {
      console.error("Error showing loading state:", error)
    }
  }

  showLoadError() {
    try {
      if (!this.hasMessagesTarget || !this.messagesTarget) return

      this.messagesTarget.innerHTML = `
        <div class="flex items-center justify-center h-full px-4 text-center">
          <p class="text-sm text-gray-500 dark:text-gray-400">
            Не вдалося завантажити чат. Спробуйте оновити сторінку.
          </p>
        </div>
      `
    } catch (error) {
      console.error("Error showing load error:", error)
    }
  }

  setupFullEventListeners() {
    try {
      if (!this.isSignedIn) return

      this.boundSendMessage = this.boundSendMessage || (() => this.sendMessage())
      this.boundInputKeypress = this.boundInputKeypress || ((e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault()
          this.sendMessage()
        }
      })

      if (this.hasSendTarget && this.sendTarget) {
        this.sendTarget.addEventListener('click', this.boundSendMessage)
      }

      if (this.hasInputTarget && this.inputTarget) {
        this.inputTarget.addEventListener('keypress', this.boundInputKeypress)
      }
    } catch (error) {
      console.error("Error setting up full event listeners:", error)
    }
  }

  removeFullEventListeners() {
    if (this.hasSendTarget && this.sendTarget && this.boundSendMessage) {
      this.sendTarget.removeEventListener('click', this.boundSendMessage)
    }

    if (this.hasInputTarget && this.inputTarget && this.boundInputKeypress) {
      this.inputTarget.removeEventListener('keypress', this.boundInputKeypress)
    }
  }

  toggleChat() {
    try {
      if (this.hasWindowTarget && this.windowTarget) {
        this.windowTarget.classList.toggle('hidden')
        if (!this.windowTarget.classList.contains('hidden')) {
          if (this.hasInputTarget && this.inputTarget && this.isSignedIn) {
            this.inputTarget.focus()
          }
          this.scrollToBottom()
        }
      }
    } catch (error) {
      console.error("Error toggling chat:", error)
    }
  }

  closeChat() {
    try {
      if (this.hasWindowTarget && this.windowTarget) {
        this.windowTarget.classList.add('hidden')
      }
    } catch (error) {
      console.error("Error closing chat:", error)
    }
  }

  sendMessage() {
    try {
      if (!this.isSignedIn) return

      if (this.hasInputTarget && this.inputTarget) {
        const message = this.inputTarget.value.trim()
        if (message && this.subscription) {
          this.subscription.perform('speak', { message: message })
          this.inputTarget.value = ''
        }
      }
    } catch (error) {
      console.error("Error sending message:", error)
    }
  }

  async loadRecentMessages() {
    const response = await fetch('/chat/recent_messages')
    if (!response.ok) throw new Error(`HTTP ${response.status}`)

    const data = await response.json()
    if (!data.messages || !Array.isArray(data.messages)) return

    if (this.hasMessagesTarget && this.messagesTarget) {
      this.messagesTarget.innerHTML = ''
    }

    data.messages.forEach(message => {
      this.addMessage(message)
    })
    this.scrollToBottom()
  }

  addMessage(data) {
    try {
      if (!this.hasMessagesTarget || !this.messagesTarget || !data) return

      const defaultAvatar = `data:image/svg+xml;base64,${this.safeBtoa(`
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
          <circle cx="16" cy="16" r="16" fill="#0891b2"/>
          <text x="16" y="20" text-anchor="middle" fill="white" font-size="12" font-family="Arial, sans-serif">
            ${(data.user_name || 'U').charAt(0).toUpperCase()}
          </text>
        </svg>
      `)}`

      const avatarUrl = data.user_avatar || defaultAvatar
      const messageHtml = `
        <div class="flex items-start space-x-3" data-message-id="${data.id || Date.now()}">
          <div class="flex-shrink-0">
            <img src="${avatarUrl}" alt="${data.user_name || 'User'}" class="w-8 h-8 rounded-full border border-cyan-200 dark:border-rose-700">
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center space-x-2 mb-1">
              <span class="font-medium text-gray-900 dark:text-white text-sm">
                ${data.user_name || 'User'}
              </span>
              <span class="text-xs text-gray-500 dark:text-gray-400">
                ${data.formatted_time || 'now'}
              </span>
            </div>
            <div class="bg-white dark:bg-gray-600 rounded-lg px-3 py-2 shadow-sm border border-gray-200 dark:border-gray-700">
              <p class="text-gray-800 dark:text-gray-200 text-sm break-words">
                ${this.escapeHtml(data.content || '')}
              </p>
            </div>
          </div>
        </div>
      `

      this.messagesTarget.insertAdjacentHTML('beforeend', messageHtml)
      if (this.isNearBottom()) {
        this.scrollToBottom()
      }
    } catch (error) {
      console.error("Error adding message:", error)
    }
  }

  scrollToBottom() {
    try {
      if (this.hasMessagesTarget && this.messagesTarget) {
        this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
      }
    } catch (error) {
      console.error("Error scrolling to bottom:", error)
    }
  }

  isNearBottom() {
    if (!this.hasMessagesTarget || !this.messagesTarget) return true

    const { scrollTop, scrollHeight, clientHeight } = this.messagesTarget
    return scrollHeight - scrollTop - clientHeight < 48
  }

  escapeHtml(text) {
    try {
      if (!text) return ''
      const div = document.createElement('div')
      div.textContent = text
      return div.innerHTML
    } catch (error) {
      console.error("Error escaping HTML:", error)
      return text || ''
    }
  }

  safeBtoa(str) {
    try {
      return btoa(unescape(encodeURIComponent(str)))
    } catch (error) {
      console.error("Error encoding to base64:", error)
      return btoa(`
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
          <circle cx="16" cy="16" r="16" fill="#0891b2"/>
          <text x="16" y="20" text-anchor="middle" fill="white" font-size="12" font-family="Arial, sans-serif">U</text>
        </svg>
      `)
    }
  }

  startResizeTopLeft = (e) => {
    e.preventDefault()
    this._startX = e.clientX
    this._startY = e.clientY
    this._startWidth = this.windowTarget.offsetWidth
    this._startHeight = this.windowTarget.offsetHeight
    document.addEventListener('mousemove', this.doResizeTopLeft)
    document.addEventListener('mouseup', this.stopResizeTopLeft)
  }

  doResizeTopLeft = (e) => {
    const minWidth = 240
    const minHeight = 240
    const maxWidth = 600
    const maxHeight = 800
    let dx = e.clientX - this._startX
    let dy = e.clientY - this._startY
    let newWidth = this._startWidth - dx
    let newHeight = this._startHeight - dy
    newWidth = Math.max(minWidth, Math.min(maxWidth, newWidth))
    newHeight = Math.max(minHeight, Math.min(maxHeight, newHeight))
    this.windowTarget.style.width = newWidth + 'px'
    this.windowTarget.style.height = newHeight + 'px'
  }

  stopResizeTopLeft = () => {
    document.removeEventListener('mousemove', this.doResizeTopLeft)
    document.removeEventListener('mouseup', this.stopResizeTopLeft)
  }

  removeResizeListeners() {
    document.removeEventListener('mousemove', this.doResizeTopLeft)
    document.removeEventListener('mouseup', this.stopResizeTopLeft)
  }
}
