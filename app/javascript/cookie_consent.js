;(function () {
  'use strict'

  var STORAGE_KEY = 'baka_cookie_consent_v1'
  var GA_ID = 'G-BW05CDN8VS'
  var ADS_CLIENT = 'ca-pub-5596031369567303'

  function prodEnabled() {
    return document.body && document.body.dataset.loadGoogleScripts === 'true'
  }

  function injectGoogle() {
    if (!prodEnabled() || window.__bakaGoogleInjected) return
    window.__bakaGoogleInjected = true

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

    var ads = document.createElement('script')
    ads.async = true
    ads.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' + ADS_CLIENT
    ads.setAttribute('crossorigin', 'anonymous')
    document.head.appendChild(ads)
  }

  function hideBanner() {
    var root = document.getElementById('cookie-consent-banner')
    if (root) root.classList.add('hidden')
  }

  function initConsentUi() {
    // Banner shows in every environment so you can verify the UI locally; only `injectGoogle` runs in production.
    var stored = localStorage.getItem(STORAGE_KEY)
    if (stored === 'accepted') {
      hideBanner()
      injectGoogle()
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
    injectGoogle()
  }

  window.bakaDeclineCookies = function () {
    localStorage.setItem(STORAGE_KEY, 'declined')
    hideBanner()
  }

  document.addEventListener('turbo:load', initConsentUi)
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initConsentUi)
  } else {
    initConsentUi()
  }
})()
