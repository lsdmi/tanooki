function initializeAccordion() {
  const accordionContainers = document.querySelectorAll('#chapters-accordion > div');

  accordionContainers.forEach(container => {
    const header = container.querySelector('div');
    const icon = header.querySelector('.accordion-icon');
    const content = container.querySelector('.accordion-content');

    icon.addEventListener('click', function(event) {
      event.preventDefault();
      event.stopPropagation();

      content.classList.toggle('hidden');
      this.classList.toggle('rotate-180');

      // Close other accordions
      accordionContainers.forEach(otherContainer => {
        if (otherContainer !== container) {
          const otherContent = otherContainer.querySelector('.accordion-content');
          const otherIcon = otherContainer.querySelector('.accordion-icon');
          otherContent.classList.add('hidden');
          otherIcon.classList.remove('rotate-180');
        }
      });
    });
  });
}
