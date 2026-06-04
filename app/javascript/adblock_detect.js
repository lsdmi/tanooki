// Lightweight bait check for the reader ad drawer only (does not touch AdSense units).

export function isAdblockLikely() {
  if (document.body?.dataset.loadAdsense !== "true") return false

  return baitElementBlocked()
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
