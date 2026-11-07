import { Controller } from "@hotwired/stimulus"
import SlimSelect from 'slim-select'
import { connectSlimSelect, disconnectSlimSelect } from 'slim_select_lifecycle'

// Slim Select with remote fiction search for bookshelf forms.
export default class extends Controller {
  static values = {
    url: String,
    placeholder: { type: String, default: 'Оберіть зі списку' },
    searchPlaceholder: { type: String, default: 'Пошук за назвою або автором' },
    closeOnSelect: { type: Boolean, default: false }
  }

  connect() {
    connectSlimSelect(this, () => new SlimSelect({
      select: this.element,
      settings: {
        closeOnSelect: this.closeOnSelectValue,
        placeholderText: this.placeholderValue,
        searchPlaceholder: this.searchPlaceholderValue,
        searchText: 'Нічого не знайдено',
        searchingText: 'Пошук...'
      },
      events: {
        search: (search) => this.fetchOptions(search)
      }
    }))
  }

  disconnect() {
    disconnectSlimSelect(this)
  }

  fetchOptions(search) {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set('q', search)

    return fetch(url, {
      headers: { Accept: 'application/json' },
      credentials: 'same-origin'
    })
      .then((response) => {
        if (!response.ok) throw new Error(`fiction_options ${response.status}`)
        return response.json()
      })
  }
}
