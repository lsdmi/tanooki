export function safeLogoSrc(url) {
  if (!url || typeof url !== "string") return null

  const trimmed = url.trim()
  if (trimmed.startsWith("//")) return null

  try {
    const parsed = new URL(trimmed, window.location.origin)
    const path = parsed.pathname
    if (!path.endsWith(".svg")) return null
    if (!path.includes("logo-default") && !path.includes("logo-dark")) return null

    const sameOrigin = parsed.origin === window.location.origin
    const cdnAssets =
      /\.digitaloceanspaces\.com$/i.test(parsed.hostname) && path.startsWith("/assets/")

    if (!sameOrigin && !cdnAssets) return null

    return parsed.href
  } catch {
    return null
  }
}
