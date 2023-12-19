const FONT_CLASSES = ['font-oswald', 'font-georgia', 'font-helvetica', 'font-times'];

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
  const currentStyle = element.getAttribute('style') || '';
  const updatedStyle = currentStyle.replace(/font-family:[^;]+;?/i, '');
  const savedFont = localStorage.getItem('selected-font');

  element.setAttribute('style', updatedStyle.trim());

  element.classList.remove(...FONT_CLASSES);
  element.classList.add(savedFont);

  // Recursively apply styles to child elements
  Array.from(element.children).forEach((child) => applyFontStyles(child));
};

document.addEventListener('turbo:load', initializeFontToggler);
