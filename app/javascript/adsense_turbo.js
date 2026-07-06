// Re-initialize AdSense after Turbo updates the page without a full reload.
// The adsbygoogle.js script loads once; each navigation needs fresh <ins> nodes + push().
;(function () {
  "use strict"

  var initialNavigation = true
  var refreshTimer = null

  function adsensePageEnabled() {
    return document.body?.dataset.loadAdsense === "true"
  }

  function scheduleAfterPaint(callback) {
    requestAnimationFrame(function () {
      requestAnimationFrame(callback)
    })
  }

  function notifyAdsenseNavigation() {
    if (!adsensePageEnabled()) return

    scheduleAfterPaint(function () {
      if (window.adsbygoogle) {
        document.dispatchEvent(new CustomEvent("baka:adsense-ready"))
      }
      document.dispatchEvent(new CustomEvent("baka:adsense-visit"))
    })
  }

  function scheduleAdsenseRefresh() {
    if (!adsensePageEnabled()) return

    if (refreshTimer) window.clearTimeout(refreshTimer)

    // Let morph finish and Stimulus connect before slots push.
    refreshTimer = window.setTimeout(function () {
      refreshTimer = null
      notifyAdsenseNavigation()
    }, 100)
  }

  function onTurboNavigation() {
    if (initialNavigation) {
      initialNavigation = false
      return
    }
    scheduleAdsenseRefresh()
  }

  document.addEventListener("turbo:load", onTurboNavigation)
  document.addEventListener("turbo:morph", onTurboNavigation)
})()
