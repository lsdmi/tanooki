/** Cyrillic-first fonts for long-form reading (Google Fonts). */
const FONT_OPTIONS = [
  {
    id: 'golos-text',
    label: 'Golos Text',
    family: '"Golos Text", ui-sans-serif, system-ui, sans-serif'
  },
  {
    id: 'literata',
    label: 'Literata',
    family: 'Literata, ui-serif, Georgia, serif'
  },
  {
    id: 'spectral',
    label: 'Spectral',
    family: 'Spectral, ui-serif, Georgia, serif'
  },
  {
    id: 'eb-garamond',
    label: 'EB Garamond',
    family: '"EB Garamond", ui-serif, Georgia, serif'
  },
  {
    id: 'pt-serif',
    label: 'PT Serif',
    family: '"PT Serif", ui-serif, Georgia, serif'
  }
]

const FONT_SIZE_MIN = 14
const FONT_SIZE_MAX = 24
const FONT_SIZE_DEFAULT = 16

const STORAGE_FONT = 'reader-font'
const STORAGE_FONT_SIZE = 'reader-font-size'

const LEGACY_FONT_CLASSES = ['', 'font-[Georgia]', 'font-[Helvetica]', 'font-[Times_New_Roman]']
const LEGACY_SIZE_CLASSES = ['', 'text-sm', 'text-base', 'text-lg', 'text-xl']
const LEGACY_SIZE_PX = [16, 14, 16, 18, 20]

/** Maps retired reader-font ids and Latin-only picks to the new Cyrillic set. */
const RETIRED_READER_FONT_IDS = {
  inter: 'golos-text',
  sora: 'golos-text',
  'plus-jakarta': 'golos-text',
  'source-serif': 'literata',
  lora: 'spectral',
  merriweather: 'eb-garamond'
}

let fontMutationObserver = null
let observedContent = null

const debounce = (fn, ms) => {
  let t
  return (...args) => {
    clearTimeout(t)
    t = setTimeout(() => fn(...args), ms)
  }
}

const disconnectFontObserver = () => {
  fontMutationObserver?.disconnect()
}

const observeFontMutations = () => {
  if (!observedContent || !fontMutationObserver) return
  fontMutationObserver.observe(observedContent, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: ['style', 'class']
  })
}

const debouncedReapplyFonts = debounce(() => {
  const root = observedContent
  if (!root || !document.body.contains(root)) return
  applyToContent(root)
}, 150)

export const getFontOptions = () => FONT_OPTIONS

export const getFontSizeBounds = () => ({
  min: FONT_SIZE_MIN,
  max: FONT_SIZE_MAX,
  default: FONT_SIZE_DEFAULT
})

const normalizeFontId = (raw) => {
  if (!raw) return FONT_OPTIONS[0].id
  if (FONT_OPTIONS.some((f) => f.id === raw)) return raw
  if (RETIRED_READER_FONT_IDS[raw]) return RETIRED_READER_FONT_IDS[raw]

  const legacyFont = LEGACY_FONT_CLASSES.indexOf(raw)
  if (legacyFont >= 0) {
    return ['golos-text', 'eb-garamond', 'golos-text', 'pt-serif'][legacyFont] || FONT_OPTIONS[0].id
  }

  return FONT_OPTIONS[0].id
}

const migrateLegacyStorage = () => {
  const currentFont = localStorage.getItem(STORAGE_FONT)
  if (currentFont) {
    const normalized = normalizeFontId(currentFont)
    if (normalized !== currentFont) localStorage.setItem(STORAGE_FONT, normalized)
  } else {
    const legacyFont = localStorage.getItem('selected-font')
    localStorage.setItem(STORAGE_FONT, normalizeFontId(legacyFont))
  }

  if (!localStorage.getItem(STORAGE_FONT_SIZE)) {
    const legacySize = localStorage.getItem('selected-font-size')
    const legacyIndex = LEGACY_SIZE_CLASSES.indexOf(legacySize)
    const px = legacyIndex >= 0 ? LEGACY_SIZE_PX[legacyIndex] : FONT_SIZE_DEFAULT
    localStorage.setItem(STORAGE_FONT_SIZE, String(px))
  }
}

export const getSavedFontId = () => {
  migrateLegacyStorage()
  return normalizeFontId(localStorage.getItem(STORAGE_FONT))
}

export const getSavedFontSize = () => {
  migrateLegacyStorage()
  const px = parseInt(localStorage.getItem(STORAGE_FONT_SIZE), 10)
  if (Number.isNaN(px)) return FONT_SIZE_DEFAULT
  return Math.min(FONT_SIZE_MAX, Math.max(FONT_SIZE_MIN, px))
}

export const setFontId = (fontId) => {
  const normalized = normalizeFontId(fontId)
  if (!FONT_OPTIONS.some((f) => f.id === normalized)) return
  localStorage.setItem(STORAGE_FONT, normalized)
  const root = document.getElementById('user-content')
  if (root) applyToContent(root)
}

export const setFontSize = (px) => {
  const size = Math.min(FONT_SIZE_MAX, Math.max(FONT_SIZE_MIN, px))
  localStorage.setItem(STORAGE_FONT_SIZE, String(size))
  const root = document.getElementById('user-content')
  if (root) applyToContent(root)
}

export const applyToContent = (element) => {
  const font = FONT_OPTIONS.find((f) => f.id === getSavedFontId()) || FONT_OPTIONS[0]
  const fontSize = getSavedFontSize()

  disconnectFontObserver()
  try {
    const walk = (el) => {
      el.style.setProperty('font-family', font.family)
      el.style.setProperty('font-size', `${fontSize}px`)

      LEGACY_FONT_CLASSES.filter(Boolean).forEach((cls) => el.classList.remove(cls))
      LEGACY_SIZE_CLASSES.filter(Boolean).forEach((cls) => el.classList.remove(cls))

      Array.from(el.children).forEach((child) => walk(child))
    }

    walk(element)
  } finally {
    observeFontMutations()
  }
}

export const bindContentObserver = () => {
  const content = document.getElementById('user-content')
  if (!content) return

  disconnectFontObserver()
  observedContent = content

  if (!fontMutationObserver) {
    fontMutationObserver = new MutationObserver(() => debouncedReapplyFonts())
  }

  applyToContent(content)
}

document.addEventListener('turbo:before-cache', () => {
  disconnectFontObserver()
  observedContent = null
})
