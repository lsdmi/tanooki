import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame", "image"]

  connect() {
    // Highlight the first image by default
    if (this.imageTargets.length > 0) {
      this.highlightImage(this.imageTargets[0])
    }
  }

  selectFiction(event) {
    const fictionId = event.currentTarget.dataset.fictionPickerIdParam

    // Remove highlight from all images
    this.imageTargets.forEach(img => {
      img.classList.remove('ring-2', 'ring-stone-500', 'dark:ring-gray-300')
    })

    // Add highlight to the clicked image
    this.highlightImage(event.currentTarget)

    if (!document.startViewTransition) {
      this.updateFrame(fictionId)
      return
    }

    document.startViewTransition(() => {
      this.updateFrame(fictionId)
    })
  }

  updateFrame(fictionId) {
    const frame = document.getElementById("fiction_details")
    frame.setAttribute('data-transitioning', 'true')

    fetch(`/fictions/${fictionId}/details`, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      const tempDiv = document.createElement('div')
      tempDiv.innerHTML = html
      const newContent = tempDiv.querySelector('turbo-stream')
      if (newContent) {
        Turbo.renderStreamMessage(newContent.outerHTML)
      }
      frame.removeAttribute('data-transitioning')
    })
  }

  highlightImage(image) {
    image.classList.add('ring-2', 'ring-stone-500', 'dark:ring-gray-300')
  }
}
