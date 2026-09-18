import { Controller } from "@hotwired/stimulus"
import SlimSelect from 'slim-select'
import { connectSlimSelect, disconnectSlimSelect } from 'slim_select_lifecycle'

// Connects to data-controller="slim"
export default class extends Controller {
  connect() {
    connectSlimSelect(this, () => new SlimSelect({
      select: this.element,
      settings: {
        closeOnSelect: false,
        placeholderText: "Оберіть зі списку",
        searchPlaceholder: 'Пошук',
        searchText: 'Нічого не знайдено',
      }
    }))
  }

  disconnect() {
    disconnectSlimSelect(this)
  }
}
