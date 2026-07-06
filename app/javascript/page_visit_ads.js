// Notify ad controllers after Turbo navigation settles (not the initial full-page load).
;(function () {
  "use strict"

  var initialTurboLoad = true

  function scheduleAfterPaint(eventName) {
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        document.dispatchEvent(new CustomEvent(eventName))
      })
    })
  }

  function notifyVisit() {
    scheduleAfterPaint("baka:banner-visit")

    if (document.body?.dataset.loadAdsense === "true") {
      scheduleAfterPaint("baka:adsense-visit")
    }
  }

  document.addEventListener("turbo:load", function () {
    if (initialTurboLoad) {
      initialTurboLoad = false
      return
    }
    notifyVisit()
  })

  document.addEventListener("turbo:morph", notifyVisit)
})()
