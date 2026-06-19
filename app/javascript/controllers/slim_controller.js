import { Controller } from "@hotwired/stimulus"
import SlimSelect from 'slim-select'

// Connects to data-controller="slim"
export default class extends Controller {
  connect() {
    this.select = new SlimSelect({
      select: this.element,
      settings: {
        closeOnSelect: false,
        placeholderText: "Оберіть зі списку",
        searchPlaceholder: 'Пошук',
        searchText: 'Нічого не знайдено',
      }
    })
  }

  disconnect() {
    this.select?.destroy()
    this.select = null
  }
}
