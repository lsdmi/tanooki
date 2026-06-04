// Heuristic adblock check before showing the reader ad drawer (bait + missing AdSense script).

export function isAdblockLikely() {
  if (document.body?.dataset.loadAdsense !== "true") return false

  if (baitElementBlocked()) return true

  const script = document.getElementById("baka-adsense-script")
  if (script?.dataset.blocked === "true") return true

  return false
}

function baitElementBlocked() {
  const bait = document.createElement("div")
  bait.setAttribute("aria-hidden", "true")
  bait.className = "adsbox ad-banner advertisement adsbygoogle"
  bait.style.cssText =
    "height:10px!important;width:10px!important;position:fixed!important;left:-10000px!important;top:0!important;pointer-events:none!important;"
  bait.textContent = " "
  document.body.appendChild(bait)

  const style = window.getComputedStyle(bait)
  const blocked =
    bait.offsetParent === null ||
    bait.offsetHeight === 0 ||
    bait.offsetWidth === 0 ||
    style.display === "none" ||
    style.visibility === "hidden"

  bait.remove()
  return blocked
}
