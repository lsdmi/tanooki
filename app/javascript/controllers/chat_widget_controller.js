import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["toggle", "window", "close", "messages", "input", "send"]

  connect() {
    console.log("Chat widget controller connected")
    // Check if user is signed in
    this.isSignedIn = this.element.querySelector('[data-chat-widget-target="input"]') !== null
    console.log("User signed in:", this.isSignedIn)
    
    // Prevent multiple initializations
    if (this.initialized) return
    
    // Add a small delay to ensure DOM is ready
    setTimeout(() => {
      this.initializeChat()
    }, 100)
  }

  disconnect() {
    console.log("Chat widget controller disconnected")
    this.cleanup()
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

  initializeChat() {
    try {
      if (this.initialized) return
      
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

      // Set up event listeners (toggle/close for everyone, send only for signed-in users)
      this.setupEventListeners()
      
      this.initialized = true
    } catch (error) {
      console.error("Error initializing chat:", error)
      // Fallback: still try to load recent messages
      this.loadRecentMessages()
    }
  }

  setupEventListeners() {
    try {
      // Toggle and close buttons work for everyone (guests and signed-in users)
      if (this.hasToggleTarget && this.toggleTarget) {
        this.toggleTarget.addEventListener('click', () => this.toggleChat())
      }

      // Close chat window
      if (this.hasCloseTarget && this.closeTarget) {
        this.closeTarget.addEventListener('click', () => this.closeChat())
      }

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
      console.error("Error setting up event listeners:", error)
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
} 