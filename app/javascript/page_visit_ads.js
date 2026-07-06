// Notify native video banner controllers after Turbo navigation (not the initial full-page load).
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

  document.addEventListener("turbo:load", function () {
    if (initialTurboLoad) {
      initialTurboLoad = false
      return
    }
    scheduleAfterPaint("baka:banner-visit")
  })

  document.addEventListener("turbo:morph", function () {
    scheduleAfterPaint("baka:banner-visit")
  })
})()
