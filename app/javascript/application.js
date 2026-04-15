// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import { Turbo } from "@hotwired/turbo-rails"
Turbo.session.drive = false

// Flatpickr portals the calendar to <body>. On failed submits Turbo often updates the page without a full reload,
// so `before-cache` alone misses — clean up on every relevant Turbo phase.
function removeFlatpickrCalendarsFromDom() {
  document.querySelectorAll('.flatpickr-calendar').forEach((el) => el.remove())
}

;['turbo:before-cache', 'turbo:before-render', 'turbo:before-stream-render'].forEach((name) => {
  document.addEventListener(name, removeFlatpickrCalendarsFromDom)
})

import "controllers";
import 'flowbite';
import "@rails/actiontext";

import Swal from "sweetalert2";
window.Swal = Swal;

// Import Action Cable channels
import "channels"
