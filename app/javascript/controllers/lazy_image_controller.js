import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const imageId = this.element.dataset.lazyImageImageId
    const spinner = document.getElementById(`spinner-${imageId}`)
    const image = document.getElementById(`image-${imageId}`)

    if (!image || !spinner) return

    // Set up lazy loading and spinner logic
    if ('IntersectionObserver' in window) {
      const observer = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting) {
          observer.disconnect()
          image.src = image.dataset.url
        }
      })
      observer.observe(image)
    } else {
      image.src = image.dataset.url
    }

    image.onload = () => {
      image.classList.remove("opacity-0")
      spinner.classList.add("hidden")
    }

    // Optional: Handle image load errors
    image.onerror = () => {
      console.error("Image failed to load")
    }
  }
}
