import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "icon", "text"]
  static values = { url: String, params: Object }

  connect() {
    // Store original button content
    this.originalContent = this.buttonTarget.innerHTML
    this.isDownloading = false
  }

  async download(event) {
    event.preventDefault()
    
    // Prevent multiple clicks if already downloading
    if (this.isDownloading) {
      return
    }

    this.isDownloading = true
    this.disableButton()
    this.showDownloadingState()

    try {
      // Get CSRF token
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

      // Build URL with parameters for GET request
      let url = this.urlValue
      if (this.hasParamsValue) {
        const urlParams = new URLSearchParams()
        Object.entries(this.paramsValue).forEach(([key, value]) => {
          if (Array.isArray(value)) {
            value.forEach(v => urlParams.append(`${key}[]`, v))
          } else {
            urlParams.append(key, value)
          }
        })
        url += '?' + urlParams.toString()
      }

      // Make the download request
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'X-CSRF-Token': csrfToken
        }
      })

      if (response.ok) {
        // Create a blob from the response
        const blob = await response.blob()
        
        // Extract filename from Content-Disposition header or use default
        const contentDisposition = response.headers.get('content-disposition')
        let filename = 'download.epub'
        if (contentDisposition) {
          const filenameMatch = contentDisposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/)
          if (filenameMatch) {
            filename = filenameMatch[1].replace(/['"]/g, '')
          }
        }
        
        // Create download link and trigger download
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = filename
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        window.URL.revokeObjectURL(url)
        
        this.showSuccessState()
      } else {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
    } catch (error) {
      console.error('Download failed:', error)
      this.showErrorState()
    } finally {
      // Re-enable button after a short delay
      setTimeout(() => {
        this.enableButton()
        this.resetButtonState()
        this.isDownloading = false
      }, 2000)
    }
  }

  disableButton() {
    this.buttonTarget.disabled = true
    this.buttonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    this.buttonTarget.classList.remove('hover:bg-stone-300', 'dark:hover:bg-gray-600', 'hover:text-stone-800', 'dark:hover:text-white')
  }

  enableButton() {
    this.buttonTarget.disabled = false
    this.buttonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    this.buttonTarget.classList.add('hover:bg-stone-300', 'dark:hover:bg-gray-600', 'hover:text-stone-800', 'dark:hover:text-white')
  }

  showDownloadingState() {
    this.buttonTarget.innerHTML = `
      <div class="flex items-center space-x-1">
        <svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span class="text-xs">Завантаження...</span>
      </div>
    `
  }

  showSuccessState() {
    this.buttonTarget.innerHTML = `
      <div class="flex items-center space-x-1">
        <svg class="h-4 w-4 text-green-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        <span class="text-xs">Готово!</span>
      </div>
    `
  }

  showErrorState() {
    this.buttonTarget.innerHTML = `
      <div class="flex items-center space-x-1">
        <svg class="h-4 w-4 text-red-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
        <span class="text-xs">Помилка!</span>
      </div>
    `
  }

  resetButtonState() {
    this.buttonTarget.innerHTML = this.originalContent
  }
}
