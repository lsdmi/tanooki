const FONT_CLASSES = ['', 'font-[Georgia]', 'font-[Helvetica]', 'font-[Times_New_Roman]'];
const FONT_SIZE_CLASSES = ['', 'text-sm', 'text-base', 'text-lg', 'text-xl'];

let fontMutationObserver = null;
let observedContent = null;

const debounce = (fn, ms) => {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
};

const disconnectFontObserver = () => {
  fontMutationObserver?.disconnect();
};

const observeFontMutations = () => {
  if (!observedContent || !fontMutationObserver) return;
  fontMutationObserver.observe(observedContent, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: ['style'],
  });
};

const debouncedReapplyFonts = debounce(() => {
  const root = observedContent;
  if (!root || !document.body.contains(root)) return;
  applyFontStyles(root);
}, 150);

const applyFontStyles = (element) => {
  const savedFont = localStorage.getItem('selected-font');
  const savedFontSize = localStorage.getItem('selected-font-size');

  disconnectFontObserver();
  try {
    const walk = (el) => {
      el.style.removeProperty('font-family');
      el.style.removeProperty('font-size');

      FONT_CLASSES.filter(Boolean).forEach((cls) => el.classList.remove(cls));
      FONT_SIZE_CLASSES.filter(Boolean).forEach((cls) => el.classList.remove(cls));

      if (savedFont && savedFont !== '') {
        el.classList.add(savedFont);
      }
      if (savedFontSize && savedFontSize !== '') {
        el.classList.add(savedFontSize);
      }

      Array.from(el.children).forEach((child) => walk(child));
    };

    walk(element);
  } finally {
    observeFontMutations();
  }
};

const initializeFontToggler = () => {
  const content = document.getElementById('user-content');

  if (!content) return;

  disconnectFontObserver();
  observedContent = content;

  if (!fontMutationObserver) {
    fontMutationObserver = new MutationObserver(() => debouncedReapplyFonts());
  }

  let currentFontIndex = FONT_CLASSES.indexOf(localStorage.getItem('selected-font'));
  if (currentFontIndex === -1) currentFontIndex = 0;

  let currentSizeIndex = FONT_SIZE_CLASSES.indexOf(localStorage.getItem('selected-font-size'));
  if (currentSizeIndex === -1) currentSizeIndex = 0;

  const toggleFont = () => {
    currentFontIndex = (currentFontIndex + 1) % FONT_CLASSES.length;
    localStorage.setItem('selected-font', FONT_CLASSES[currentFontIndex]);
    applyFontStyles(content);
  };

  const toggleFontSize = () => {
    currentSizeIndex = (currentSizeIndex + 1) % FONT_SIZE_CLASSES.length;
    localStorage.setItem('selected-font-size', FONT_SIZE_CLASSES[currentSizeIndex]);
    applyFontStyles(content);
  };

  const fontToggleButton = document.getElementById('font-toggle');
  if (fontToggleButton) fontToggleButton.addEventListener('click', toggleFont);

  const fontSizeToggleButton = document.getElementById('font-size-toggle');
  if (fontSizeToggleButton) fontSizeToggleButton.addEventListener('click', toggleFontSize);

  applyFontStyles(content);
};

document.addEventListener('turbo:before-cache', () => {
  disconnectFontObserver();
  observedContent = null;
});

document.addEventListener('turbo:load', initializeFontToggler);
