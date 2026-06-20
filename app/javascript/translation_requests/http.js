import { Turbo } from "@hotwired/turbo-rails"

export function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
}

export function safeHttpUrl(url) {
  const trimmed = (url || '').trim()
  if (!trimmed) return null

  try {
    const parsed = new URL(trimmed)
    if (parsed.protocol === 'http:' || parsed.protocol === 'https:') {
      return parsed.href
    }
  } catch {
    return null
  }

  return null
}

export async function fetchTurboStream(url, { signal } = {}) {
  const response = await fetch(url, {
    method: 'GET',
    headers: {
      Accept: 'text/vnd.turbo-stream.html',
      'X-CSRF-Token': csrfToken()
    },
    signal
  })

  if (!response.ok) throw new Error(`HTTP ${response.status}`)

  return response.text()
}

export function applyTurboStream(html, targetId = 'requests-container') {
  const parser = new DOMParser()
  const doc = parser.parseFromString(html, 'text/html')
  const hasTargetUpdate = [...doc.querySelectorAll('turbo-stream')].some(
    (element) =>
      element.getAttribute('action') === 'update' &&
      element.getAttribute('target') === targetId
  )

  if (!hasTargetUpdate) return false

  Turbo.renderStreamMessage(html)
  return true
}

export async function fetchJson(url, { method = 'GET', body = null } = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken(),
    Accept: 'application/json'
  }

  const response = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : null
  })

  const data = await response.json()
  return { response, data }
}
