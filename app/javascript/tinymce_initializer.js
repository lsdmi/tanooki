const initializeTinymce = () => {
  const textarea = document.querySelector('.tinymce');
  if (!textarea) return;

  const textareaIframe = document.querySelector('.tox-tinymce');
  if (textareaIframe) textareaIframe.remove();

  tinymce.remove();
  tinymce.util.I18n.add('uk', {
    'Align': 'Вирівнювання',
    'Advanced': 'Додатково',
    'Alternative description': 'Опис',
    'Alternative source URL': 'Альтернативний URL',
    'Background color': 'Колір тла',
    'Blockquote': 'Цитата',
    'Bold': 'Жирний',
    'Cancel': 'Відмінити',
    'Center': 'По центру',
    'Characters (no spaces)': 'Символів (без пробілів)',
    'Characters': 'Символів (всього)',
    'Clear formatting': 'Очистити форматування',
    'Close': 'Вийти',
    'Code': 'Код',
    'Color picker': 'Вибір кольору',
    'Count': 'Кількість',
    'Current window': 'Поточне вікно',
    'Decrease indent': 'Зменшити відступ',
    'Document': 'Документ',
    'Embed': 'Вставити',
    'Fonts': 'Шрифти',
    'Font sizes': 'Розмір шрифту',
    'General': 'Загальне',
    'Height': 'Висота',
    'Horizontal line': 'Горизонтальна лінія',
    'Increase indent': 'Збільшити відступ',
    'Insert/edit image': 'Вставити/редагувати зображення',
    'Insert/edit media': 'Вставити/редагувати медіа',
    'Insert/edit link': 'Вставити/редагувати посилання',
    'Italic': 'Курсив',
    'Justify': 'По ширині',
    'Left': 'Ліворуч',
    'Line height': 'Висота рядка',
    'Link': 'Посилання',
    'Media poster (Image URL)': 'Постер (URL зображення)',
    'New window': 'Нове вікно',
    'Open link in...': 'Відкрити посилання в...',
    'Paste your embed code below:': 'Вставте код нижче:',
    'Redo': 'Повторити',
    'Right': 'Праворуч',
    'Save': 'Зберегти',
    'Selection': 'Виділене',
    'Source': 'Джерело',
    'Source code': 'Вихідний код',
    'System Font': 'Шрифт',
    'Text to display': 'Текст для відображення',
    'Underline': 'Підкреслення',
    'Undo': 'Відмінити',
    'Width': 'Ширина',
    'Word count': 'Кількість слів',
    'Words': 'Слів',
    'Strikethrough': 'Закреслення',
    'Text color': 'Колір тексту',
    'Fore color': 'Колір тексту',
    'Background color': 'Колір тла'
  });
  tinymce.init({
    language: 'uk',
    selector: 'textarea',
    height: 500,
    plugins: [
      'autosave',
      'code',
      'image',
      'link',
      'lists',
      'media',
      'quickbars',
      'wordcount',
      'textcolor'
    ],
    menubar: false,
    toolbar: 'undo redo | bold italic underline strikethrough | forecolor | link | fontfamily fontsize align lineheight | removeformat | outdent indent | image media | hr | code | wordcount',
    quickbars_insert_toolbar: 'image media',
    quickbars_selection_toolbar: 'bold italic underline strikethrough | forecolor | blockquote quicklink',
    contextmenu: false,
    statusbar: false,
    newline_behavior: 'linebreak',
    link_title: false,
    setup: function(editor) {
      editor.on('init', function() {
        // Apply custom styles to the content area
        const iframe = editor.getContainer().querySelector('iframe');
        if (iframe && iframe.contentDocument) {
          // Detect dark mode from parent window
          const isDark = localStorage.getItem('color-theme') === 'dark' ||
            (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches);
          
          const style = iframe.contentDocument.createElement('style');
          style.textContent = `
            body {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
              font-size: 16px;
              line-height: 1.6;
              margin: 0;
              padding: 20px;
            }
            
            /* Typography */
            h1, h2, h3, h4, h5, h6 {
              font-weight: 600;
              line-height: 1.3;
              margin-top: 1.5em;
              margin-bottom: 0.5em;
              color: ${isDark ? '#f43f5e' : '#0891b2'};
            }
            
            h1 { font-size: 2em; }
            h2 { font-size: 1.75em; }
            h3 { font-size: 1.5em; }
            h4 { font-size: 1.25em; }
            h5 { font-size: 1.1em; }
            h6 { font-size: 1em; }
            
            p {
              margin-bottom: 1em;
              text-align: justify;
            }
            
            /* Links */
            a {
              color: ${isDark ? '#f43f5e' : '#0891b2'};
              text-decoration: underline;
              transition: color 0.2s ease;
            }
            
            a:hover {
              color: ${isDark ? '#e11d48' : '#0e7490'};
            }
            
            /* Lists */
            ul, ol {
              margin: 1em 0;
              padding-left: 2em;
            }
            
            li {
              margin-bottom: 0.5em;
            }
            
            /* Blockquotes */
            blockquote {
              border-left: 3px solid ${isDark ? '#f43f5e' : '#0891b2'};
              padding-left: 1em;
              margin: 1.5em 0;
              font-style: italic;
              color: ${isDark ? '#9ca3af' : '#6b7280'};
            }
            
            /* Code */
            code {
              background: ${isDark ? '#374151' : '#f3f4f6'};
              padding: 0.2em 0.4em;
              border-radius: 3px;
              font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
              font-size: 0.9em;
              color: ${isDark ? '#f87171' : '#dc2626'};
            }
            
            pre {
              background: ${isDark ? '#374151' : '#f9fafb'};
              color: ${isDark ? '#f1f5f9' : '#374151'};
              padding: 1em;
              border-radius: 6px;
              overflow-x: auto;
              margin: 1.5em 0;
            }
            
            pre code {
              background: transparent;
              color: inherit;
              padding: 0;
            }
            
            /* Images */
            img {
              max-width: 100%;
              height: auto;
              border-radius: 6px;
              margin: 1em 0;
            }
            
            /* Tables */
            table {
              border-collapse: collapse;
              width: 100%;
              margin: 1.5em 0;
            }
            
            th, td {
              border: 1px solid ${isDark ? '#374151' : '#e5e7eb'};
              padding: 0.75em;
              text-align: left;
            }
            
            th {
              background: ${isDark ? '#374151' : '#f9fafb'};
              font-weight: 600;
            }
            
            /* Horizontal rules */
            hr {
              border: none;
              border-top: 2px solid ${isDark ? '#6b7280' : '#e5e7eb'};
              margin: 2em 0;
            }
            
            /* Emphasis */
            strong, b {
              font-weight: 600;
            }
            
            em, i {
              font-style: italic;
            }
            
            strike, s, del {
              text-decoration: line-through;
              opacity: 0.7;
            }
            
            /* Selection styles */
            ::selection {
              background: ${isDark ? 'rgba(244, 63, 94, 0.3)' : 'rgba(8, 145, 178, 0.3)'};
              color: ${isDark ? '#f9fafb' : '#111827'};
            }
            
            ::-moz-selection {
              background: ${isDark ? 'rgba(244, 63, 94, 0.3)' : 'rgba(8, 145, 178, 0.3)'};
              color: ${isDark ? '#f9fafb' : '#111827'};
            }
          `;
          iframe.contentDocument.head.appendChild(style);
        }
        
        // Style the TinyMCE editor header/toolbar
        const editorContainer = editor.getContainer();
        const header = editorContainer.querySelector('.tox-editor-header');
        if (header) {
          const isDark = localStorage.getItem('color-theme') === 'dark' ||
            (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches);
          
          const headerStyle = document.createElement('style');
          headerStyle.textContent = `
            .tox-editor-header {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#d1d5db'} !important;
              border-radius: 6px 6px 0 0 !important;
              padding: 8px !important;
            }
            
            .tox-editor-header .tox-toolbar-overlord {
              background: transparent !important;
            }
            
            .tox-editor-header .tox-toolbar__primary {
              background: transparent !important;
            }
            
            .tox-editor-header .tox-toolbar {
              background: transparent !important;
              border: none !important;
            }
            
            .tox-toolbar__overflow {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              border-radius: 6px !important;
              box-shadow: 0 4px 12px ${isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)'} !important;
            }
            
            .tox-toolbar__overflow .tox-tbtn {
              background: transparent !important;
              border: none !important;
              color: ${isDark ? '#f1f5f9' : '#374151'} !important;
            }
            
            .tox-toolbar__overflow .tox-tbtn:hover {
              background: ${isDark ? '#4b5563' : '#f3f4f6'} !important;
              color: ${isDark ? '#f1f5f9' : '#374151'} !important;
            }
            
            .tox-toolbar__group {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: none !important;
              margin: 0 2px !important;
              padding: 2px !important;
            }
            
            .tox-editor-header .tox-tbtn {
              background: transparent !important;
              border: none !important;
              color: ${isDark ? '#f1f5f9' : '#374151'} !important;
              transition: color 0.2s ease !important;
            }
            
            .tox-editor-header .tox-tbtn:hover {
              background: ${isDark ? '#4b5563' : '#f3f4f6'} !important;
              color: ${isDark ? '#f43f5e' : '#0891b2'} !important;
            }
            
            .tox-editor-header .tox-tbtn--disabled {
              opacity: 0.4 !important;
            }
            
            .tox-editor-header .tox-tbtn--select {
              background: transparent !important;
            }
            
            .tox-editor-header .tox-tbtn__select-label {
              color: ${isDark ? '#f1f5f9' : '#374151'} !important;
            }
            
            .tox-tbtn__select-chevron svg {
              fill: ${isDark ? '#f1f5f9' : '#374151'} !important;
            }
            
            .tox-editor-header .tox-split-button {
              background: transparent !important;
              border: none !important;
            }
            
            .tox-editor-header .tox-split-button:hover {
              background: ${isDark ? '#4b5563' : '#f3f4f6'} !important;
            }
            
            .tox-editor-header .tox-split-button__chevron svg {
              fill: ${isDark ? '#f1f5f9' : '#374151'} !important;
            }
            
            .tox-icon svg {
              fill: ${isDark ? '#f1f5f9' : '#374151'} !important;
            }
            
            .tox-tbtn:hover .tox-icon svg {
              fill: ${isDark ? '#f1f5f9' : '#374151'} !important;
            }
            
            /* Additional specificity for nested elements */
            .tox-toolbar__group .tox-tbtn {
              background: transparent !important;
              border: none !important;
            }
            
            .tox-toolbar__group .tox-tbtn:hover {
              background: ${isDark ? '#4b5563' : '#f3f4f6'} !important;
            }
            
            .tox-tbtn .tox-icon svg {
              fill: ${isDark ? '#f1f5f9' : '#374151'} !important;
            }
            
            .tox-tbtn:hover .tox-icon svg {
              fill: ${isDark ? '#f1f5f9' : '#374151'} !important;
            }
            
            /* Edit area border */
            .tox-edit-area::before {
              border: 1px solid ${isDark ? '#4b5563' : '#d1d5db'} !important;
            }
            
            /* Dialog styling */
            .tox-dialog {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              border-radius: 8px !important;
              box-shadow: 0 10px 25px ${isDark ? 'rgba(0, 0, 0, 0.5)' : 'rgba(0, 0, 0, 0.1)'} !important;
            }
            
            .tox-dialog__header {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border-bottom: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              border-radius: 8px 8px 0 0 !important;
              padding: 12px 16px !important;
            }
            
            .tox-dialog__title {
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
              font-weight: 600 !important;
              font-size: 16px !important;
            }
            
            .tox-dialog__body {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
              padding: 16px !important;
            }
            
            .tox-dialog__footer {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border-top: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              border-radius: 0 0 8px 8px !important;
              padding: 12px 16px !important;
            }
            
            .tox-dialog__footer .tox-dialog__footer-end {
              gap: 8px !important;
            }
            
            .tox-dialog__footer .tox-button {
              background: ${isDark ? '#4b5563' : '#f3f4f6'} !important;
              border: 1px solid ${isDark ? '#6b7280' : '#d1d5db'} !important;
              color: ${isDark ? '#f9fafb' : '#374151'} !important;
              border-radius: 6px !important;
              padding: 8px 16px !important;
              font-size: 14px !important;
              font-weight: 500 !important;
              transition: all 0.2s ease !important;
            }
            
            .tox-dialog__footer .tox-button:hover {
              background: ${isDark ? '#6b7280' : '#e5e7eb'} !important;
              border-color: ${isDark ? '#9ca3af' : '#9ca3af'} !important;
            }
            
            .tox-dialog__footer .tox-button--primary {
              background: ${isDark ? '#f43f5e' : '#0891b2'} !important;
              border-color: ${isDark ? '#f43f5e' : '#0891b2'} !important;
              color: white !important;
            }
            
            .tox-dialog__footer .tox-button--primary:hover {
              background: ${isDark ? '#e11d48' : '#0e7490'} !important;
              border-color: ${isDark ? '#e11d48' : '#0e7490'} !important;
            }
            
            .tox-dialog__footer .tox-button--secondary {
              background: transparent !important;
              border-color: ${isDark ? '#6b7280' : '#d1d5db'} !important;
              color: ${isDark ? '#f9fafb' : '#374151'} !important;
            }
            
            .tox-dialog__footer .tox-button--secondary:hover {
              background: ${isDark ? 'rgba(244, 63, 94, 0.1)' : 'rgba(8, 145, 178, 0.1)'} !important;
              border-color: ${isDark ? '#f43f5e' : '#0891b2'} !important;
              color: ${isDark ? '#f43f5e' : '#0891b2'} !important;
            }
            
            /* Dialog form elements */
            .tox-dialog__body .tox-form__group {
              margin-bottom: 16px !important;
            }
            
            .tox-dialog__body .tox-form__group__label,
            .tox-dialog__body .tox-label {
              color: ${isDark ? '#f9fafb' : '#374151'} !important;
              font-weight: 500 !important;
              margin-bottom: 4px !important;
              display: block !important;
            }
            
            .tox-dialog__body .tox-textfield,
            .tox-dialog__body .tox-textarea {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
              border-radius: 6px !important;
              padding: 8px 12px !important;
              font-size: 14px !important;
              transition: all 0.2s ease !important;
            }
            
            .tox-dialog__body .tox-textfield:focus,
            .tox-dialog__body .tox-textarea:focus {
              border-color: ${isDark ? '#f43f5e' : '#0891b2'} !important;
              box-shadow: 0 0 0 2px ${isDark ? 'rgba(244, 63, 94, 0.2)' : 'rgba(8, 145, 178, 0.2)'} !important;
              outline: none !important;
            }
            
            .tox-dialog__body .tox-selectfield {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#d1d5db'} !important;
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
              border-radius: 6px !important;
              padding: 8px 12px !important;
              font-size: 14px !important;
            }
            
            .tox-dialog__body .tox-selectfield:focus {
              border-color: ${isDark ? '#f43f5e' : '#0891b2'} !important;
              box-shadow: 0 0 0 2px ${isDark ? 'rgba(244, 63, 94, 0.2)' : 'rgba(8, 145, 178, 0.2)'} !important;
              outline: none !important;
            }
            
            .tox-listboxfield {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#d1d5db'} !important;
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
              border-radius: 6px !important;
              padding: 8px 12px !important;
              font-size: 14px !important;
            }
            
            .tox-listbox__select-label {
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
            }
            
            .tox-listboxfield .tox-listbox__select-chevron svg {
              fill: ${isDark ? '#f9fafb' : '#111827'} !important;
            }
            
            .tox-listbox--select {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#d1d5db'} !important;
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
              border-radius: 6px !important;
              padding: 8px 12px !important;
              font-size: 14px !important;
            }
            
            /* Dialog navigation */
            .tox-dialog__body-nav {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border-bottom: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              padding: 8px 16px !important;
            }
            
            .tox-dialog__body-nav-item {
              background: transparent !important;
              border: none !important;
              color: ${isDark ? '#9ca3af' : '#6b7280'} !important;
              padding: 8px 12px !important;
              margin-right: 8px !important;
              border-radius: 4px !important;
              transition: all 0.2s ease !important;
            }
            
            .tox-dialog__body-nav-item--active {
              background: ${isDark ? '#4b5563' : '#f3f4f6'} !important;
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
            }
            
            .tox-dialog__body-nav-item:hover {
              background: ${isDark ? '#4b5563' : '#f3f4f6'} !important;
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
            }
            
            /* Collection items (dropdowns, menus) */
            .tox-collection__item-label {
              color: ${isDark ? '#f9fafb' : '#111827'} !important;
              font-size: 14px !important;
              margin: 4px !important;
              transition: all 0.2s ease !important;
            }
            
            .tox-collection__item:hover .tox-collection__item-label {
              background: ${isDark ? '#4b5563' : '#f3f4f6'} !important;
            }
            
            .tox-menu-nav__js {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              border-radius: 4px !important;
              margin: 4px !important;
              box-shadow: 0 4px 12px ${isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)'} !important;
            }
            
            .tox-collection__item {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: none !important;
              transition: all 0.2s ease !important;
            }
            
            .tox-collection__item:hover {
              background: ${isDark ? '#4b5563' : '#f3f4f6'} !important;
            }
            
            /* Menu and collection styling */
            .tox-menu {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              border-radius: 6px !important;
              box-shadow: 0 4px 12px ${isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)'} !important;
            }
            
            .tox-collection {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              border-radius: 6px !important;
            }
            
            .tox-collection--list {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              border-radius: 6px !important;
            }
            
            .tox-selected-menu {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              border-radius: 6px !important;
              box-shadow: 0 4px 12px ${isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)'} !important;
            }
            
            /* Pop dialog styling */
            .tox-pop__dialog {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border: 1px solid ${isDark ? '#4b5563' : '#e5e7eb'} !important;
              border-radius: 6px !important;
              box-shadow: 0 4px 12px ${isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)'} !important;
            }
            
            .tox-pop__dialog::before {
              background: ${isDark ? '#374151' : '#f9fafb'} !important;
              border-color: ${isDark ? '#4b5563' : '#e5e7eb'} !important;
            }
            
            /* Dialog overlay */
            .tox-dialog-wrap {
              background: ${isDark ? 'rgba(0, 0, 0, 0.7)' : 'rgba(0, 0, 0, 0.5)'} !important;
            }
            
            .tox-dialog-wrap__backdrop--opaque {
              background: transparent !important;
            }
            
            /* Dialog close button */
            .tox-dialog__header .tox-dialog__header-end .tox-button {
              background: transparent !important;
              border: none !important;
              color: ${isDark ? '#9ca3af' : '#6b7280'} !important;
              padding: 4px !important;
              border-radius: 4px !important;
              transition: all 0.2s ease !important;
            }
            
            .tox-dialog__header .tox-dialog__header-end .tox-button:hover {
              background: ${isDark ? 'rgba(244, 63, 94, 0.1)' : 'rgba(8, 145, 178, 0.1)'} !important;
              color: ${isDark ? '#f43f5e' : '#0891b2'} !important;
            }
          `;
          document.head.appendChild(headerStyle);
        }
      });
    }
  });
};

document.addEventListener('turbo:load', initializeTinymce);
document.addEventListener('turbo:render', initializeTinymce);
