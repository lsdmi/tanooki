import { safeLogoSrc } from "safe_logo_src"

const THEME_ICON_PAIRS = [
  ['theme-toggle-dark-icon', 'theme-toggle-light-icon'],
  ['reader-theme-toggle-dark-icon', 'reader-theme-toggle-light-icon'],
];

const initializeModeToggler = () => {
  const themeToggleBtn = document.getElementById('theme-toggle');
  const readerThemeToggleBtn = document.getElementById('reader-theme-toggle');
  if (!themeToggleBtn && !readerThemeToggleBtn) return;

  const siteLogo = document.getElementById('site-logo');
  const defaultLogo = siteLogo ? safeLogoSrc(siteLogo.getAttribute('data-default-logo')) : null;
  const darkLogo = siteLogo ? safeLogoSrc(siteLogo.getAttribute('data-dark-logo')) : null;

  const setLogo = (isDark) => {
    if (siteLogo && defaultLogo && darkLogo) siteLogo.src = isDark ? darkLogo : defaultLogo;
  };

  const setIconVisibility = (isDark) => {
    THEME_ICON_PAIRS.forEach(([darkId, lightId]) => {
      const darkIcon = document.getElementById(darkId);
      const lightIcon = document.getElementById(lightId);
      if (darkIcon) darkIcon.style.display = isDark ? 'none' : 'inline';
      if (lightIcon) lightIcon.style.display = isDark ? 'inline' : 'none';
    });

    const readerLabel = document.getElementById('reader-theme-toggle-label');
    if (readerLabel) readerLabel.textContent = isDark ? 'Світла тема' : 'Темна тема';
  };

  const bindThemeToggle = (btn) => {
    if (!btn || btn.dataset.modeTogglerBound === 'true') return;
    btn.dataset.modeTogglerBound = 'true';
    btn.addEventListener('click', performThemeToggle);
  };

  const performThemeToggle = () => {
    document.documentElement.classList.toggle('dark');
    const newIsDark = document.documentElement.classList.contains('dark');
    localStorage.setItem('color-theme', newIsDark ? 'dark' : 'light');
    setLogo(newIsDark);
    setIconVisibility(newIsDark);
    document.cookie = `color_theme=${newIsDark ? 'dark' : 'light'}; path=/; max-age=31536000`;

    if (typeof tinymce !== 'undefined') {
      setTimeout(() => {
        const editorContainer = document.querySelector('.tox-tinymce');
        if (editorContainer) updateTinymceStyles(newIsDark);
      }, 100);
    }
  };

  // Function to update TinyMCE styles based on current theme
  const updateTinymceStyles = (isDark) => {
    window.applyEditorContentTheme?.(isDark);
    
    // Update toolbar and dialog styles
    const existingHeaderStyle = document.querySelector('style[data-tinymce-header-theme]');
    if (existingHeaderStyle) {
      existingHeaderStyle.remove();
    }
    
    const headerStyle = document.createElement('style');
    headerStyle.setAttribute('data-tinymce-header-theme', 'true');
    headerStyle.textContent = `
      .tox-tinymce {
        border: 1px solid ${isDark ? '#52525b' : '#d1d5db'} !important;
        border-radius: 10px !important;
      }

      .tox-editor-header {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#d1d5db'} !important;
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
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        border-radius: 6px !important;
        box-shadow: 0 4px 12px ${isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)'} !important;
      }
      
      .tox-toolbar__overflow .tox-tbtn {
        background: transparent !important;
        border: none !important;
        color: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }
      
      .tox-toolbar__overflow .tox-tbtn:hover {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
        color: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }
      
      .tox-toolbar__group {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: none !important;
        margin: 0 2px !important;
        padding: 2px !important;
      }
      
      .tox-editor-header .tox-tbtn {
        background: transparent !important;
        border: none !important;
        color: ${isDark ? '#f4f4f5' : '#374151'} !important;
        transition: color 0.2s ease !important;
      }
      
      .tox-editor-header .tox-tbtn:hover {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
        color: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }
      
      .tox-editor-header .tox-tbtn--disabled {
        opacity: 0.4 !important;
      }
      
      .tox-editor-header .tox-tbtn--select {
        background: transparent !important;
      }
      
      .tox-editor-header .tox-tbtn__select-label {
        color: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }
      
      .tox-tbtn__select-chevron svg {
        fill: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }
      
      .tox-editor-header .tox-split-button {
        background: transparent !important;
        border: none !important;
      }
      
      .tox-editor-header .tox-split-button:hover {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
      }
      
      .tox-editor-header .tox-split-button__chevron svg {
        fill: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }
      
      .tox-icon svg {
        fill: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }
      
      .tox-tbtn:hover .tox-icon svg {
        fill: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }

      .tox-tbtn[data-mce-name="tooltip"] .tox-icon svg,
      .tox-tbtn[data-mce-name="tooltip"] .tox-icon svg path,
      .tox-tbtn[data-mce-name="tooltip"]:hover .tox-icon svg,
      .tox-tbtn[data-mce-name="tooltip"]:hover .tox-icon svg path {
        fill: none !important;
        stroke: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }
      
      /* Additional specificity for nested elements */
      .tox-toolbar__group .tox-tbtn {
        background: transparent !important;
        border: none !important;
      }
      
      .tox-toolbar__group .tox-tbtn:hover {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
      }
      
      .tox-tbtn .tox-icon svg {
        fill: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }
      
      .tox-tbtn:hover .tox-icon svg {
        fill: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }
      
      /* Edit area border */
      .tox-edit-area::before {
        border: 1px solid ${isDark ? '#52525b' : '#d1d5db'} !important;
      }
      
      /* Dialog styling */
      .tox-dialog {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        border-radius: 8px !important;
        box-shadow: 0 10px 25px ${isDark ? 'rgba(0, 0, 0, 0.5)' : 'rgba(0, 0, 0, 0.1)'} !important;
      }
      
      .tox-dialog__header {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border-bottom: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        border-radius: 8px 8px 0 0 !important;
        padding: 12px 16px !important;
      }
      
      .tox-dialog__title {
        color: ${isDark ? '#fafafa' : '#111827'} !important;
        font-weight: 600 !important;
        font-size: 16px !important;
      }
      
      .tox-dialog__body {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        color: ${isDark ? '#fafafa' : '#111827'} !important;
        padding: 16px !important;
      }
      
      .tox-dialog__footer {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border-top: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        border-radius: 0 0 8px 8px !important;
        padding: 12px 16px !important;
      }
      
      .tox-dialog__footer .tox-dialog__footer-end {
        gap: 8px !important;
      }
      
      .tox-dialog__footer .tox-button {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
        border: 1px solid ${isDark ? '#71717a' : '#d1d5db'} !important;
        color: ${isDark ? '#fafafa' : '#374151'} !important;
        border-radius: 6px !important;
        padding: 8px 16px !important;
        font-size: 14px !important;
        font-weight: 500 !important;
        transition: all 0.2s ease !important;
      }
      
      .tox-dialog__footer .tox-button:hover {
        background: ${isDark ? '#71717a' : '#e5e7eb'} !important;
        border-color: ${isDark ? '#a1a1aa' : '#9ca3af'} !important;
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
        border-color: ${isDark ? '#71717a' : '#d1d5db'} !important;
        color: ${isDark ? '#fafafa' : '#374151'} !important;
      }
      
      .tox-dialog__footer .tox-button--secondary:hover {
        background: ${isDark ? 'rgba(244, 63, 94, 0.1)' : 'rgba(8, 145, 178, 0.1)'} !important;
        border-color: ${isDark ? '#f43f5e' : '#0891b2'} !important;
        color: ${isDark ? '#f43f5e' : '#0891b2'} !important;
      }

      /* Search options (gear) is a toolbar button dropped into the dialog, so the skin paints it white. */
      .tox-dialog .tox-tbtn {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
        color: ${isDark ? '#fafafa' : '#374151'} !important;
        border: 1px solid ${isDark ? '#71717a' : '#d1d5db'} !important;
        border-radius: 6px !important;
        margin: 0 !important;
        box-shadow: none !important;
      }

      .tox-dialog .tox-tbtn:hover,
      .tox-dialog .tox-tbtn--enabled {
        background: ${isDark ? '#71717a' : '#e5e7eb'} !important;
      }

      .tox-dialog .tox-tbtn svg {
        fill: ${isDark ? '#fafafa' : '#374151'} !important;
      }

      .tox-dialog .tox-button--naked {
        background: transparent !important;
        border-color: transparent !important;
        color: ${isDark ? '#fafafa' : '#374151'} !important;
      }

      .tox-dialog .tox-button--naked .tox-icon svg {
        fill: ${isDark ? '#fafafa' : '#374151'} !important;
      }
      
      /* Dialog form elements */
      .tox-dialog__body .tox-form__group {
        margin-bottom: 16px !important;
      }
      
      .tox-dialog__body .tox-form__group__label,
      .tox-dialog__body .tox-label {
        color: ${isDark ? '#fafafa' : '#374151'} !important;
        font-weight: 500 !important;
        margin-bottom: 4px !important;
        display: block !important;
      }
      
      .tox-dialog__body .tox-textfield,
      .tox-dialog__body .tox-textarea {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        color: ${isDark ? '#fafafa' : '#111827'} !important;
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
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#d1d5db'} !important;
        color: ${isDark ? '#fafafa' : '#111827'} !important;
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
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#d1d5db'} !important;
        color: ${isDark ? '#fafafa' : '#111827'} !important;
        border-radius: 6px !important;
        padding: 8px 12px !important;
        font-size: 14px !important;
      }
      
      .tox-listbox__select-label {
        color: ${isDark ? '#fafafa' : '#111827'} !important;
      }
      
      .tox-listboxfield .tox-listbox__select-chevron svg {
        fill: ${isDark ? '#fafafa' : '#111827'} !important;
      }
      
      .tox-listbox--select {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#d1d5db'} !important;
        color: ${isDark ? '#fafafa' : '#111827'} !important;
        border-radius: 6px !important;
        padding: 8px 12px !important;
        font-size: 14px !important;
      }
      
      /* Dialog navigation */
      .tox-dialog__body-nav {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border-bottom: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        padding: 8px 16px !important;
      }
      
      .tox-dialog__body-nav-item {
        background: transparent !important;
        border: none !important;
        color: ${isDark ? '#a1a1aa' : '#6b7280'} !important;
        padding: 8px 12px !important;
        margin-right: 8px !important;
        border-radius: 4px !important;
        transition: all 0.2s ease !important;
      }
      
      .tox-dialog__body-nav-item--active {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
        color: ${isDark ? '#fafafa' : '#111827'} !important;
      }
      
      .tox-dialog__body-nav-item:hover {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
        color: ${isDark ? '#fafafa' : '#111827'} !important;
      }
      
      /* Collection items (dropdowns, menus) */
      .tox-collection__item-label,
      .tox-collection__item-label :is(h1, h2, h3, h4, h5, h6, p, blockquote) {
        background: transparent !important;
        border: 0 !important;
        box-shadow: none !important;
        color: ${isDark ? '#fafafa' : '#111827'} !important;
      }

      .tox-collection__item-label {
        font-size: 14px !important;
        margin: 4px !important;
        padding: 0 !important;
        transition: all 0.2s ease !important;
      }
      
      .tox-collection__item:hover .tox-collection__item-label {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
      }
      
      .tox-menu-nav__js {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        border-radius: 4px !important;
        margin: 4px !important;
        box-shadow: 0 4px 12px ${isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)'} !important;
      }
      
      .tox-collection__item {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: none !important;
        transition: all 0.2s ease !important;
      }
      
      .tox-collection__item:hover {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
      }
      
      /* Menu and collection styling */
      .tox-menu {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        border-radius: 6px !important;
        box-shadow: 0 4px 12px ${isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)'} !important;
      }
      
      .tox-collection {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        border-radius: 6px !important;
      }
      
      .tox-collection--list {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        border-radius: 6px !important;
      }
      
      .tox-selected-menu {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        border-radius: 6px !important;
        box-shadow: 0 4px 12px ${isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)'} !important;
      }
      
      /* Pop dialog styling */
      .tox-pop__dialog {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border: 1px solid ${isDark ? '#52525b' : '#e5e7eb'} !important;
        border-radius: 6px !important;
        box-shadow: 0 4px 12px ${isDark ? 'rgba(0, 0, 0, 0.3)' : 'rgba(0, 0, 0, 0.1)'} !important;
      }
      
      .tox-pop__dialog::before {
        background: ${isDark ? '#3f3f46' : '#f9fafb'} !important;
        border-color: ${isDark ? '#52525b' : '#e5e7eb'} !important;
      }

      .tox-pop .tox-tbtn,
      .tox-pop .tox-tbtn:hover {
        color: ${isDark ? '#f4f4f5' : '#374151'} !important;
      }

      .tox-pop .tox-tbtn:hover {
        background: ${isDark ? '#52525b' : '#f3f4f6'} !important;
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
        color: ${isDark ? '#a1a1aa' : '#6b7280'} !important;
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
  };

  const isDark =
    localStorage.getItem('color-theme') === 'dark' ||
    (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches);

  document.documentElement.classList.toggle('dark', isDark);
  setLogo(isDark);
  setIconVisibility(isDark);
  
  // Apply initial TinyMCE styles if editor exists
  if (typeof tinymce !== 'undefined') {
    // Wait a bit for TinyMCE to initialize
    setTimeout(() => {
      const editorContainer = document.querySelector('.tox-tinymce');
      if (editorContainer) {
        updateTinymceStyles(isDark);
      }
    }, 100);
  }

  bindThemeToggle(themeToggleBtn);
  bindThemeToggle(readerThemeToggleBtn);
};

document.addEventListener('turbo:load', initializeModeToggler);
