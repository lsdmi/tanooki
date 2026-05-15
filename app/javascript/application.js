// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import { Turbo } from "@hotwired/turbo-rails"
import "controllers"
import 'flowbite'
import Swal from "sweetalert2"
import "channels"

Turbo.session.drive = false

window.Swal = Swal

// Flatpickr portals the calendar to <body>. On failed submits Turbo often updates the page without a full reload,
// so `before-cache` alone misses — clean up on every relevant Turbo phase.
function removeFlatpickrCalendarsFromDom() {
  document.querySelectorAll('.flatpickr-calendar').forEach((el) => el.remove())
}

;['turbo:before-cache', 'turbo:before-render', 'turbo:before-stream-render'].forEach((name) => {
  document.addEventListener(name, removeFlatpickrCalendarsFromDom)
})

function bindFictionsOrderToggleSpin() {
  document.querySelectorAll('.fictions-order-toggle:not([data-order-spin-bound])').forEach((btn) => {
    btn.dataset.orderSpinBound = 'true'
    btn.addEventListener('click', () => {
      btn.classList.add('animate-spin')
      window.setTimeout(() => btn.classList.remove('animate-spin'), 500)
    })
  })
}

document.addEventListener('turbo:load', bindFictionsOrderToggleSpin)
document.addEventListener('turbo:frame-load', bindFictionsOrderToggleSpin)
