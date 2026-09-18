// Re-initialize AdSense after Turbo updates the page without a full reload.
// The adsbygoogle.js script loads once; each navigation needs fresh <ins> nodes + push().
;(function () {
  "use strict"

  // Skip the in-flight first load only when this file evaluated before turbo:load.
  // Deferred import after window.load must still refresh on the next navigation.
  var skipNextLoad = document.readyState !== 'complete'
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
    if (skipNextLoad) {
      skipNextLoad = false
      return
    }
    scheduleAdsenseRefresh()
  }

  document.addEventListener("turbo:load", onTurboNavigation)
  document.addEventListener("turbo:morph", onTurboNavigation)
})()
