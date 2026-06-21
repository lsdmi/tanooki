// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import { Turbo } from "@hotwired/turbo-rails"
import "turbo_transitions"
import "controllers"
import 'flowbite'
import "channels"
import "cookie_consent"

// SPA-like navigation — Turbo 8 Drive + prefetch (morph when <head> matches)
Turbo.session.drive = true
Turbo.setProgressBarDelay(120)
