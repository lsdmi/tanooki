// Adblock bait check — used by in-chapter AdSense slots and the reader ad drawer.

export function syncAdblockDocumentClass() {
  if (document.body?.dataset.loadAdsense !== "true") {
    document.documentElement.classList.remove("adblock-likely")
    return false
  }

  const blocked = baitElementBlocked()
  document.documentElement.classList.toggle("adblock-likely", blocked)
  return blocked
}

export function isAdblockLikely() {
  if (document.body?.dataset.loadAdsense !== "true") return false
  if (document.documentElement.classList.contains("adblock-likely")) return true

  return syncAdblockDocumentClass()
}

function baitElementBlocked() {
  const bait = document.createElement("div")
  bait.setAttribute("aria-hidden", "true")
  bait.className = "adsbox"
  bait.style.cssText =
    "position:absolute!important;top:-1px!important;left:-1px!important;width:1px!important;height:1px!important;pointer-events:none!important;"
  bait.textContent = "\u00a0"
  document.body.appendChild(bait)

  const style = window.getComputedStyle(bait)
  const blocked =
    style.display === "none" ||
    style.visibility === "hidden" ||
    bait.offsetHeight === 0 ||
    bait.offsetWidth === 0

  bait.remove()
  return blocked
}
