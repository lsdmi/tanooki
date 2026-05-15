function initializeAccordion() {
  document.querySelectorAll('[data-chapters-accordion-root]').forEach((root) => {
    const accordionContainers = Array.from(root.children);

    accordionContainers.forEach((container) => {
      if (container.dataset.chaptersAccordionInit === 'true') return;

      const header = container.querySelector('div');
      const icon = header?.querySelector('.accordion-icon');
      const content = container.querySelector('.accordion-content');
      if (!header || !icon || !content) return;

      container.dataset.chaptersAccordionInit = 'true';

      icon.addEventListener('click', function (event) {
        event.preventDefault();
        event.stopPropagation();

        content.classList.toggle('hidden');
        this.classList.toggle('rotate-180');

        accordionContainers.forEach((otherContainer) => {
          if (otherContainer !== container) {
            const otherContent = otherContainer.querySelector('.accordion-content');
            const otherIcon = otherContainer.querySelector('.accordion-icon');
            otherContent?.classList.add('hidden');
            otherIcon?.classList.remove('rotate-180');
          }
        });
      });
    });
  });
}

window.initializeAccordion = initializeAccordion;
