import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  filter(event) {
    const url = event.currentTarget.dataset.searchFilterUrlValue
    
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
      console.error('Filter error:', error)
    })
  }
}

