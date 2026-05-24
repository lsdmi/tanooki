function buildChapterSectionUrl(baseUrl, extraParams) {
  const url = new URL(baseUrl, window.location.href);
  Object.entries(extraParams).forEach(([key, value]) => {
    if (value === null || value === undefined || value === '') return;
    url.searchParams.set(key, String(value));
  });
  return `${url.pathname}${url.search}`;
}

function initializeAccordion() {
  document.querySelectorAll('[data-chapters-accordion-root]').forEach((root) => {
    const accordionContainers = Array.from(root.children);

    accordionContainers.forEach((container) => {
      if (container.dataset.chaptersAccordionInit === 'true') return;

      const header = container.querySelector('.accordion-header');
      const icon = header?.querySelector('.accordion-icon');
      const content = container.querySelector('.accordion-content');
      if (!header || !icon || !content) return;

      container.dataset.chaptersAccordionInit = 'true';

      header.addEventListener('click', function (event) {
        if (event.target.closest('[data-epub-download-target]')) return;

        event.preventDefault();

        const wasHidden = content.classList.contains('hidden');
        content.classList.toggle('hidden');
        icon.classList.toggle('rotate-180');

        if (wasHidden) {
          loadLazyChapterSection(content);
        }

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

async function loadLazyChapterSection(content) {
  const container = content.querySelector('[data-chapter-section-url]');
  if (!container || container.dataset.chapterSectionLoaded === 'true') return;

  const baseUrl = container.dataset.chapterSectionUrl;
  if (!baseUrl) return;

  container.dataset.chapterSectionLoaded = 'true';

  let extraParams = {};
  try {
    extraParams = JSON.parse(container.dataset.chapterSectionParams || '{}');
  } catch {
    extraParams = {};
  }

  const url = buildChapterSectionUrl(baseUrl, extraParams);
  const placeholder = container.querySelector('.chapter-section-placeholder');
  if (placeholder) {
    placeholder.textContent = 'Завантаження…';
  }

  try {
    const response = await fetch(url, {
      headers: { Accept: 'text/html', 'X-Requested-With': 'XMLHttpRequest' },
      credentials: 'same-origin',
    });
    if (!response.ok) {
      container.dataset.chapterSectionLoaded = 'false';
      if (placeholder) {
        placeholder.textContent = 'Не вдалося завантажити розділи. Спробуйте ще раз.';
      }
      return;
    }
    const html = await response.text();
    if (!html.includes('<li')) {
      container.dataset.chapterSectionLoaded = 'false';
      if (placeholder) {
        placeholder.textContent = 'Розділів не знайдено.';
      }
      return;
    }
    container.innerHTML = html;
  } catch {
    container.dataset.chapterSectionLoaded = 'false';
    if (placeholder) {
      placeholder.textContent = 'Не вдалося завантажити розділи. Спробуйте ще раз.';
    }
  }
}

window.initializeAccordion = initializeAccordion;
