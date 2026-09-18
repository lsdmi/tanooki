// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import { Turbo } from "@hotwired/turbo-rails"
import "turbo_transitions"
import "controllers"
import 'flowbite'
import "adblock_early"
import "pwa"

// SPA-like navigation — Turbo 8 Drive + prefetch (morph when <head> matches)
Turbo.session.drive = true
// Prefetch + morph often finish under 300ms; bar appears only on slower full swaps.
Turbo.setProgressBarDelay(300)

function importWhenIdle(moduleId) {
  const load = () => {
    import(moduleId)
  }

  if (typeof requestIdleCallback === "function") {
    requestIdleCallback(load, { timeout: 2000 })
    return
  }

  window.setTimeout(load, 1)
}

function deferSecondaryModules() {
  importWhenIdle("channels")
  importWhenIdle("cookie_consent")
  importWhenIdle("adsense_turbo")
}

if (document.readyState === "complete") {
  deferSecondaryModules()
} else {
  window.addEventListener("load", deferSecondaryModules)
}
