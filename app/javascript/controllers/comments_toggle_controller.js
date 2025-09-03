import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon", "contentSection", "commentsSection", "commentsModal"]

    connect() {
    // Initialize state - comments are visible by default
    this.commentsVisible = true
    this.updateUI()

    // Listen for window resize to handle screen size changes
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener('resize', this.handleResize)

    // Listen for Turbo events to handle comment updates
    this.handleTurboEvent = this.handleTurboEvent.bind(this)
    document.addEventListener('turbo:frame-load', this.handleTurboEvent)
  }

  disconnect() {
    window.removeEventListener('resize', this.handleResize)
    document.removeEventListener('turbo:frame-load', this.handleTurboEvent)
  }

  handleTurboEvent(event) {
    // Handle Turbo frame updates
    console.log('Turbo frame loaded:', event.detail)
  }

  handleResize() {
    // Update UI when screen size changes
    this.updateUI()
  }

      recreateDesktopSidebar() {
    // This method is no longer needed since we keep the desktop sidebar in the DOM
    // and just hide/show it with CSS classes
  }

    updateUI() {
    const contentSection = this.contentSectionTarget
    const commentsModal = this.commentsModalTarget
    const icon = this.iconTarget

    // Only manage desktop sidebar visibility on large screens
    if (window.innerWidth >= 1024) {
      // Get the desktop sidebar element
      const commentsSection = this.element.querySelector('[data-comments-toggle-target="commentsSection"]')
      
      // Ensure mobile modal is hidden on large screens
      commentsModal.classList.add('hidden')
      
      if (commentsSection) {
        if (this.commentsVisible) {
          // Show comments - 2/3 content, 1/3 comments on desktop
          contentSection.classList.remove("lg:w-full")
          contentSection.classList.add("lg:w-2/3")
          commentsSection.classList.remove("hidden")
          commentsSection.classList.add("lg:w-1/3")
        } else {
          // Hide comments - 3/3 content on desktop
          contentSection.classList.remove("lg:w-2/3")
          contentSection.classList.add("lg:w-full")
          commentsSection.classList.add("hidden")
          commentsSection.classList.remove("lg:w-1/3")
        }
      }
    } else {
      // On small screens, hide desktop sidebar but keep it in DOM
      const commentsSection = this.element.querySelector('[data-comments-toggle-target="commentsSection"]')
      if (commentsSection) {
        commentsSection.classList.add('hidden')
        commentsSection.classList.remove('lg:w-1/3')
      }
    }

    // Update icon to show comments are visible
    icon.innerHTML = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>`
  }

  toggle() {
    // Check if we're on mobile (screen width < 1024px)
    if (window.innerWidth < 1024) {
      this.toggleModal()
    } else {
      // Desktop behavior - toggle sidebar
      this.commentsVisible = !this.commentsVisible
      this.updateUI()
    }
  }

  toggleModal() {
    const commentsModal = this.commentsModalTarget
    const isHidden = commentsModal.classList.contains('hidden')

    if (isHidden) {
      this.showModal()
    } else {
      this.hideModal()
    }
  }

  showModal() {
    const commentsModal = this.commentsModalTarget
    commentsModal.classList.remove('hidden')

    // Prevent body scroll when sidebar is open
    document.body.style.overflow = 'hidden'

    // Force reflow to ensure the sidebar is visible before animation
    commentsModal.offsetHeight

    // Add animation class for slide in from right effect
    const sidebarContent = commentsModal.querySelector('.fixed.right-0')
    sidebarContent.classList.remove('translate-x-full')
    sidebarContent.classList.add('translate-x-0')
  }

  hideModal() {
    const commentsModal = this.commentsModalTarget
    const sidebarContent = commentsModal.querySelector('.fixed.right-0')

    // Add slide out to right animation
    sidebarContent.classList.remove('translate-x-0')
    sidebarContent.classList.add('translate-x-full')

    // Hide sidebar after animation
    setTimeout(() => {
      commentsModal.classList.add('hidden')
      document.body.style.overflow = ''
    }, 300)
  }

  closeModal() {
    this.hideModal()
  }
}
