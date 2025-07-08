import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["toggle", "window", "close", "messages", "input", "send", "resizeHandleTopLeft"]

  connect() {
    console.log("Chat widget controller connected")
    // Check if user is signed in
    this.isSignedIn = this.element.querySelector('[data-chat-widget-target="input"]') !== null
    console.log("User signed in:", this.isSignedIn)

    // Don't initialize immediately - wait for first click
    this.initialized = false
    this.isLoading = false

    // Set up basic toggle functionality without full initialization
    this.setupBasicEventListeners()

    // Add resize listeners for top-left handle
    if (this.hasResizeHandleTopLeftTarget && this.hasWindowTarget) {
      this.resizeHandleTopLeftTarget.addEventListener('mousedown', this.startResizeTopLeft)
    }
  }

  disconnect() {
    console.log("Chat widget controller disconnected")
    this.cleanup()
    // Remove resize listeners for top-left handle
    if (this.hasResizeHandleTopLeftTarget) {
      this.resizeHandleTopLeftTarget.removeEventListener('mousedown', this.startResizeTopLeft)
    }
    this.removeResizeListeners()
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
      // Toggle button - will initialize chat on first click
      if (this.hasToggleTarget && this.toggleTarget) {
        this.toggleTarget.addEventListener('click', () => this.handleToggleClick())
      }

      // Close chat window
      if (this.hasCloseTarget && this.closeTarget) {
        this.closeTarget.addEventListener('click', () => this.closeChat())
      }
    } catch (error) {
      console.error("Error setting up basic event listeners:", error)
    }
  }

  async handleToggleClick() {
    try {
      // If not initialized, initialize first
      if (!this.initialized && !this.isLoading) {
        await this.initializeChat()
      }
      
      // Then toggle the chat window
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

      // Initialize Action Cable subscription (guests can still receive messages)
      this.subscription = consumer.subscriptions.create("ChatChannel", {
        connected: () => {
          console.log("Connected to chat channel from widget")
          this.loadRecentMessages()
        },

        disconnected: () => {
          console.log("Disconnected from chat channel")
        },

        rejected: () => {
          console.log("Connection rejected - loading messages without real-time updates")
          // Still load recent messages even if WebSocket connection fails
          this.loadRecentMessages()
        },

        received: (data) => {
          this.addMessage(data)
        }
      })

      // Set up full event listeners for signed-in users
      this.setupFullEventListeners()
      
      this.initialized = true
      this.isLoading = false
      this.hideLoadingState()
    } catch (error) {
      console.error("Error initializing chat:", error)
      this.isLoading = false
      this.hideLoadingState()
      // Fallback: still try to load recent messages
      this.loadRecentMessages()
    }
  }

  showLoadingState() {
    try {
      if (this.hasMessagesTarget && this.messagesTarget) {
        this.messagesTarget.innerHTML = `
          <div class="flex items-center justify-center h-full">
            <div class="flex items-center space-x-2 text-gray-500 dark:text-gray-400">
              <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-cyan-600 dark:border-rose-400"></div>
              <span class="text-sm">Завантаження чату...</span>
            </div>
          </div>
        `
      }
    } catch (error) {
      console.error("Error showing loading state:", error)
    }
  }

  hideLoadingState() {
    // Loading state will be replaced by actual messages
  }

  setupFullEventListeners() {
    try {
      // Send message and input events only for signed-in users
      if (this.isSignedIn) {
        // Send message
        if (this.hasSendTarget && this.sendTarget) {
          this.sendTarget.addEventListener('click', () => this.sendMessage())
        }

        // Enter key to send
        if (this.hasInputTarget && this.inputTarget) {
          this.inputTarget.addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault()
              this.sendMessage()
            }
          })
        }
      }
    } catch (error) {
      console.error("Error setting up full event listeners:", error)
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
      // Only allow sending if user is signed in
      if (!this.isSignedIn) {
        console.log("Guest users cannot send messages")
        return
      }

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

  loadRecentMessages() {
    try {
      // Load recent messages via AJAX (works for both guests and signed-in users)
      fetch('/chat/recent_messages')
        .then(response => response.json())
        .then(data => {
          if (data.messages && Array.isArray(data.messages)) {
            data.messages.forEach(message => {
              this.addMessage(message)
            })
            this.scrollToBottom()
          }
        })
        .catch(error => {
          console.error('Error loading recent messages:', error)
        })
    } catch (error) {
      console.error("Error in loadRecentMessages:", error)
    }
  }

  addMessage(data) {
    try {
      if (!this.hasMessagesTarget || !this.messagesTarget || !data) return

      // Default avatar as a simple colored circle with initials (matching your color scheme)
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
      this.scrollToBottom()
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

  // Safe base64 encoding for Unicode characters
  safeBtoa(str) {
    try {
      return btoa(unescape(encodeURIComponent(str)))
    } catch (error) {
      console.error("Error encoding to base64:", error)
      // Fallback to a simple default avatar
      return btoa(`
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
          <circle cx="16" cy="16" r="16" fill="#0891b2"/>
          <text x="16" y="20" text-anchor="middle" fill="white" font-size="12" font-family="Arial, sans-serif">U</text>
        </svg>
      `)
    }
  }

  // --- Resize logic for top-left ---
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
    // Do NOT set left, top, or position
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