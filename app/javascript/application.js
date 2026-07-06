// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import { Turbo } from "@hotwired/turbo-rails"
import "turbo_transitions"
import "controllers"
import 'flowbite'
import "channels"
import "cookie_consent"
import "adblock_early"
import "adsense_turbo"
import "page_visit_ads"
import "pwa"

// SPA-like navigation — Turbo 8 Drive + prefetch (morph when <head> matches)
Turbo.session.drive = true
// Prefetch + morph often finish under 300ms; bar appears only on slower full swaps.
Turbo.setProgressBarDelay(300)
