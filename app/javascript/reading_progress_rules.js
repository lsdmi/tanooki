// When a chapter page counts as "engaged" (moves the resume cursor) and "completed" (joins the read set).
// Kept free of DOM and Stimulus so the thresholds can be tested on their own; reading_progress_controller.js
// measures the page and asks these.

export const MIN_DWELL_MS = 4000
export const ENGAGED_DWELL_MS = 8000
export const ENGAGED_DWELL_SEEN = 0.15
export const ENGAGED_SCROLL_SEEN = 0.25
export const COMPLETED_SEEN = 0.9
export const NEXT_SEEN = 0.7

// The furthest fraction of the chapter text that has entered the viewport, never going back.
export function seenFraction(previous, { top, height }, viewportHeight) {
  if (height <= 0) return previous

  const seen = (viewportHeight - top) / height
  return Math.max(previous, Math.min(1, Math.max(0, seen)))
}

export function fitsScreen({ height }, viewportHeight) {
  return height <= viewportHeight
}

// One-screen chapters are fully seen on load, so for them only dwell proves reading.
export function isEngaged({ dwellMs, seen, fits }) {
  if (dwellMs < MIN_DWELL_MS) return false
  if (fits) return dwellMs >= ENGAGED_DWELL_MS

  return (dwellMs >= ENGAGED_DWELL_MS && seen >= ENGAGED_DWELL_SEEN) || seen >= ENGAGED_SCROLL_SEEN
}

// `via` is "scroll" while reading, or "next" when the reader presses «Наступний розділ».
export function isCompleted({ seen, fits }, via) {
  return fits || seen >= (via === "next" ? NEXT_SEEN : COMPLETED_SEEN)
}
