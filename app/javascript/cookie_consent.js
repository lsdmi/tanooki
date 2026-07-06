;(function () {
  'use strict'

  var STORAGE_KEY = 'baka_cookie_consent_v1'
  var GA_ID = 'G-BW05CDN8VS'
  var ADS_CLIENT = 'ca-pub-5596031369567303'

  function prodEnabled() {
    return document.body && document.body.dataset.loadGoogleScripts === 'true'
  }

  function adsenseEnabled() {
    return prodEnabled() && document.body.dataset.loadAdsense === 'true'
  }

  var ADSENSE_SCRIPT_ID = 'baka-adsense-script'

  function notifyAdsenseReady() {
    if (window.adsbygoogle) {
      document.dispatchEvent(new CustomEvent('baka:adsense-ready'))
    }
  }

  // Let Stimulus connect in-chapter adsense-unit controllers before the ready event fires.
  function scheduleAdsenseReadyForUnits() {
    if (!adsenseEnabled()) return
    requestAnimationFrame(function () {
      requestAnimationFrame(notifyAdsenseReady)
    })
  }

  function injectAdSense() {
    if (!adsenseEnabled()) return
    if (window.__bakaAdSenseInjected) {
      notifyAdsenseReady()
      return
    }
    window.__bakaAdSenseInjected = true

    var ads = document.createElement('script')
    ads.id = ADSENSE_SCRIPT_ID
    ads.async = true
    ads.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' + ADS_CLIENT
    ads.setAttribute('crossorigin', 'anonymous')
    ads.onload = notifyAdsenseReady
    document.head.appendChild(ads)
  }

  function removeAdSense() {
    if (!window.__bakaAdSenseInjected) return

    var script = document.getElementById(ADSENSE_SCRIPT_ID)
    if (script) script.remove()

    document.querySelectorAll('script[src*="pagead2.googlesyndication.com/pagead/js/adsbygoogle"]').forEach(function (node) {
      node.remove()
    })
    document.querySelectorAll('ins.adsbygoogle, .google-auto-placed').forEach(function (node) {
      node.remove()
    })

    window.__bakaAdSenseInjected = false
    delete window.adsbygoogle
  }

  function syncAdSense() {
    if (adsenseEnabled()) {
      injectAdSense()
    } else {
      removeAdSense()
    }
  }

  function injectAnalytics() {
    if (!prodEnabled() || window.__bakaAnalyticsInjected) return
    window.__bakaAnalyticsInjected = true

    var gtagScript = document.createElement('script')
    gtagScript.async = true
    gtagScript.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID
    document.head.appendChild(gtagScript)

    gtagScript.onload = function () {
      window.dataLayer = window.dataLayer || []
      function gtag() {
        window.dataLayer.push(arguments)
      }
      window.gtag = gtag
      gtag('js', new Date())
      gtag('config', GA_ID)
    }
  }

  function hideBanner() {
    var root = document.getElementById('cookie-consent-banner')
    if (root) root.classList.add('hidden')
  }

  function initConsentUi() {
    // Banner is visible in every environment for UI checks; AdSense/Analytics scripts load only in production.
    // Re-sync on turbo:load so AdSense does not persist after navigating to ad-excluded pages.
    syncAdSense()
    scheduleAdsenseReadyForUnits()

    var stored = localStorage.getItem(STORAGE_KEY)
    if (stored === 'accepted') {
      hideBanner()
      injectAnalytics()
      return
    }
    if (stored === 'declined') {
      hideBanner()
      return
    }

    var root = document.getElementById('cookie-consent-banner')
    if (root) root.classList.remove('hidden')
  }

  window.bakaAcceptCookies = function () {
    localStorage.setItem(STORAGE_KEY, 'accepted')
    hideBanner()
    injectAnalytics()
  }

  window.bakaDeclineCookies = function () {
    localStorage.setItem(STORAGE_KEY, 'declined')
    hideBanner()
  }

  // Script inject + first paint ready; turbo navigation refresh lives in adsense_turbo.js.
  document.addEventListener('turbo:load', initConsentUi)
})()
