import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log('Search pagination controller connected', this.element)
  }

  paginate(event) {
    console.log('Paginate clicked', event.currentTarget)
    event.preventDefault()
    
    const link = event.currentTarget
    if (link.getAttribute('aria-disabled') === 'true') {
      return
    }
    
    const url = link.getAttribute('href')
    console.log('Fetching pagination URL:', url)
    
    fetch(url, {
      headers: {
        Accept: "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Pagination error:', error)
    })
  }
}

