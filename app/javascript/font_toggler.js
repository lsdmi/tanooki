const FONT_CLASSES = ['', 'font-oswald', 'font-georgia', 'font-helvetica', 'font-times'];

const initializeFontToggler = () => {
  const content = document.getElementById('user-content');

  if (!content) return;

  let currentIndex = 0;

  const toggleFont = () => {
    currentIndex = (currentIndex + 1) % FONT_CLASSES.length;
    localStorage.setItem('selected-font', FONT_CLASSES[currentIndex]);

    applyFontStyles(content);
  };

  const fontToggleButton = document.getElementById('font-toggle');
  fontToggleButton.addEventListener('click', toggleFont);

  applyFontStyles(content);
};

const applyFontStyles = (element) => {
  const savedFont = localStorage.getItem('selected-font');

  FONT_CLASSES.filter((cls) => cls).forEach((cls) => element.classList.remove(cls));

  if (savedFont && savedFont !== '') {
    element.classList.add(savedFont);
  }

  Array.from(element.children).forEach((child) => applyFontStyles(child));
};

document.addEventListener('turbo:load', initializeFontToggler);
