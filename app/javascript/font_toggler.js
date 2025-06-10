const FONT_CLASSES = ['', 'font-[Georgia]', 'font-[Helvetica]', 'font-[Times_New_Roman]'];
const FONT_SIZE_CLASSES = ['', 'text-sm', 'text-base', 'text-lg', 'text-xl'];

const initializeFontToggler = () => {
  const content = document.getElementById('user-content');

  if (!content) return;

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

const applyFontStyles = (element) => {
  const savedFont = localStorage.getItem('selected-font');
  const savedFontSize = localStorage.getItem('selected-font-size');

  FONT_CLASSES.filter(Boolean).forEach((cls) => element.classList.remove(cls));
  FONT_SIZE_CLASSES.filter(Boolean).forEach((cls) => element.classList.remove(cls));

  if (savedFont && savedFont !== '') {
    element.classList.add(savedFont);
  }
  if (savedFontSize && savedFontSize !== '') {
    element.classList.add(savedFontSize);
  }

  Array.from(element.children).forEach((child) => applyFontStyles(child));
};

document.addEventListener('turbo:load', initializeFontToggler);
