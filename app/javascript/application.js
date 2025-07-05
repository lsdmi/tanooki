// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import { Turbo } from "@hotwired/turbo-rails"
Turbo.session.drive = false

import "controllers";
import 'flowbite';
import "@rails/actiontext";

import Swal from "sweetalert2";
window.Swal = Swal;

// Import Action Cable channels
import "channels"
