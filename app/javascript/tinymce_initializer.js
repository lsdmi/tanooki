// Resolves with the stored image URL; on failure the image stays inline and the
// after-save job moves it to storage.
const uploadChapterImage = (url, blobInfo, progress) => new Promise((resolve, reject) => {
  const xhr = new XMLHttpRequest();
  xhr.open('POST', url);
  xhr.setRequestHeader('Accept', 'application/json');
  const token = document.querySelector('meta[name="csrf-token"]')?.content;
  if (token) xhr.setRequestHeader('X-CSRF-Token', token);

  xhr.upload.onprogress = (event) => {
    if (event.lengthComputable) progress((event.loaded / event.total) * 100);
  };
  xhr.onload = () => {
    let data = {};
    try { data = JSON.parse(xhr.responseText); } catch (_error) { data = {}; }

    if (xhr.status >= 200 && xhr.status < 300 && data.location) resolve(data.location);
    else reject({ message: data.error || `HTTP ${xhr.status}`, remove: false });
  };
  xhr.onerror = () => reject({ message: 'Не вдалося надіслати зображення', remove: false });

  const body = new FormData();
  body.append('file', blobInfo.blob(), blobInfo.filename());
  xhr.send(body);
});

// Only forms that opt in (the chapter form) upload images instead of keeping base64.
const imageUploadOptions = (textarea) => {
  const url = textarea.dataset.imageUploadUrl;
  if (!url) return {};

  return {
    automatic_uploads: true,
    paste_data_images: true,
    images_file_types: 'jpeg,jpg,jpe,jfi,jif,jfif,png,gif,webp,bmp,tif,tiff',
    images_upload_handler: (blobInfo, progress) => uploadChapterImage(url, blobInfo, progress),
    // Keep stored URLs as returned: absolute on the CDN, root-relative in development.
    relative_urls: false,
    remove_script_host: true
  };
};

// Kept in step with UserContent::LinkScrubber::YOUTUBE_EMBED_HOSTS: only these embed URLs survive rendering.
const YOUTUBE_EMBED_HOSTS = new Set(['www.youtube.com', 'www.youtube-nocookie.com']);
const YOUTUBE_ID = /^[A-Za-z0-9_-]+$/;

const decodeAttr = (value) => value
  .replace(/&amp;/gi, '&')
  .replace(/&quot;/gi, '"')
  .replace(/&#39;|&apos;/gi, "'")
  .replace(/&lt;/gi, '<')
  .replace(/&gt;/gi, '>');

const escapeAttr = (value) => value.replace(/&/g, '&amp;').replace(/"/g, '&quot;');

const parseHttpUrl = (value) => {
  try {
    return new URL(value.trim());
  } catch (_error) {
    return null;
  }
};

const isAllowedYoutubeEmbed = (value) => {
  if (!value || /[\s<>"']/.test(value)) return false;

  const url = parseHttpUrl(value);
  if (!url || url.protocol !== 'https:' || url.port || url.username || url.password) return false;

  const host = url.hostname.toLowerCase();
  return YOUTUBE_EMBED_HOSTS.has(host) && /^\/embed\/[A-Za-z0-9_-]+\/?$/.test(url.pathname);
};

const embedUrl = (host, id, params) => {
  const query = params.toString();
  return `https://${host}/embed/${id}${query ? `?${query}` : ''}`;
};

const safeParams = (url, keys) => {
  const params = new URLSearchParams();
  keys.forEach((key) => {
    const value = url.searchParams.get(key);
    if (value && YOUTUBE_ID.test(value)) params.set(key, value);
  });
  const timestamp = url.searchParams.get('t');
  if (timestamp && /^\d+s?$/.test(timestamp) && !params.has('start')) params.set('start', timestamp.replace(/s$/, ''));
  return params;
};

// Watch, share, and Shorts links become an embed URL. An address that is already an allowed embed is rebuilt
// with only playback parameters. Anything else (another site, http, data:, javascript:) is rejected.
const youtubeEmbedSrc = (raw) => {
  const input = String(raw ?? '').trim();
  if (!input) return null;

  const snippet = input.match(/<iframe\b[^>]*\bsrc\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+))/i);
  const candidate = decodeAttr(snippet ? (snippet[1] || snippet[2] || snippet[3] || '') : input);
  const url = parseHttpUrl(candidate);
  if (!url || url.protocol !== 'https:' || url.port || url.username || url.password) return null;

  const host = url.hostname.toLowerCase();
  if (YOUTUBE_EMBED_HOSTS.has(host)) {
    const embedId = url.pathname.match(/^\/embed\/([A-Za-z0-9_-]+)\/?$/);
    if (embedId) return embedUrl(host, embedId[1], safeParams(url, ['start', 'end', 'list', 'index']));
  }

  if (host === 'youtu.be') {
    const id = url.pathname.split('/').filter(Boolean)[0];
    return id && YOUTUBE_ID.test(id) ? embedUrl('www.youtube.com', id, safeParams(url, ['start', 'end', 'list'])) : null;
  }

  if (host !== 'www.youtube.com' && host !== 'youtube.com' && host !== 'm.youtube.com') return null;

  const pathId = url.pathname.match(/^\/(?:shorts|live|embed)\/([A-Za-z0-9_-]+)\/?$/);
  const watchId = url.pathname === '/watch' ? url.searchParams.get('v') : null;
  const id = pathId?.[1] || (watchId && YOUTUBE_ID.test(watchId) ? watchId : null);
  return id ? embedUrl('www.youtube.com', id, safeParams(url, ['start', 'end', 'list', 'index'])) : null;
};

const iframeTagPattern = () => /<iframe\b(?:[^>"']|"[^"]*"|'[^']*')*\/?>(?:\s*<\/iframe\s*>)?/gi;

// Leaves an already-allowed embed tag untouched, so opening a chapter does not rewrite it.
const sanitizeIframeHtml = (html) => {
  if (!/<iframe\b/i.test(html)) return { html, removed: false };

  let removed = false;
  const next = html.replace(iframeTagPattern(), (tag) => {
    const srcMatch = tag.match(/\bsrc\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+))/i);
    const raw = decodeAttr(srcMatch?.[1] ?? srcMatch?.[2] ?? srcMatch?.[3] ?? '');
    if (isAllowedYoutubeEmbed(raw)) return tag;

    const embed = youtubeEmbedSrc(raw);
    if (!embed) {
      removed = true;
      return '';
    }

    return `<iframe src="${escapeAttr(embed)}" width="560" height="314" frameborder="0" allowfullscreen="allowfullscreen"></iframe>`;
  });

  return { html: next, removed };
};

const selectedIframeSrc = (editor) => {
  const node = editor.selection.getNode();
  const object = editor.dom.getParent(node, '[data-mce-object="iframe"]') || (node?.nodeName === 'IFRAME' ? node : null);
  return object?.getAttribute('data-mce-p-src') || object?.getAttribute('src') || '';
};

const openYoutubeDialog = (editor) => {
  editor.windowManager.open({
    title: editor.translate('Insert YouTube video'),
    body: {
      type: 'panel',
      items: [
        {
          type: 'input',
          name: 'url',
          label: editor.translate('YouTube URL'),
          placeholder: 'https://www.youtube.com/watch?v=…'
        }
      ]
    },
    initialData: { url: selectedIframeSrc(editor) },
    buttons: [
      { type: 'cancel', text: editor.translate('Cancel') },
      { type: 'submit', text: editor.translate('Save'), primary: true }
    ],
    onSubmit: (api) => {
      const src = youtubeEmbedSrc(api.getData().url);
      if (!src) {
        editor.notificationManager.open({
          text: editor.translate('Only a YouTube link can be embedded'),
          type: 'warning',
          timeout: 8000
        });
        return;
      }

      editor.insertContent(`<iframe src="${escapeAttr(src)}" width="560" height="314" frameborder="0" allowfullscreen="allowfullscreen"></iframe>`);
      api.close();
    }
  });
};

const READER_FONTS_URL = 'https://fonts.googleapis.com/css2?family=Golos+Text:wght@400;500;600&display=swap';
const READER_FONT_FAMILY = '"Golos Text", ui-sans-serif, system-ui, sans-serif';
const READER_FONT_SIZE = 16;
// Keep in sync with HEADING_SCALE in reader_preferences.js.
const HEADING_SCALE = { h1: 1.75, h2: 1.5, h3: 1.25, h4: 1.1, h5: 1.1, h6: 1.1 };

const prefersDarkTheme = () => localStorage.getItem('color-theme') === 'dark' ||
  (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches);

// Content area styles copied from what the chapter reader computes (actiontext.css, chapters_reader.css,
// application.css note styles, reader_preferences.js defaults). Font, size, and color are flattened in
// both the chapter and publication editors. `#tinymce` outranks TinyMCE's default content CSS.
const editorContentCss = (isDark) => {
  const theme = isDark
    ? { background: '#18181b', text: '#e4e4e7', quote: '#52525b', note: '244, 63, 94' }
    : { background: '#fafaf9', text: '#292524', quote: '#d6d3d1', note: '8, 145, 178' };
  const headingSizes = Object.entries(HEADING_SCALE)
    .map(([tag, scale]) => `#tinymce ${tag} { font-size: ${Math.round(READER_FONT_SIZE * scale)}px !important; }`)
    .join('\n');

  return `
    #tinymce {
      margin: 0;
      padding: 20px;
      background: ${theme.background};
      color: ${theme.text};
      font-family: ${READER_FONT_FAMILY};
      font-size: ${READER_FONT_SIZE}px;
      line-height: 1.625;
      text-align: start;
      overflow-wrap: anywhere;
    }
    @media (max-width: 639px) {
      #tinymce { padding: 12px 8px; }
    }
    #tinymce * { font-family: inherit !important; font-size: inherit !important; color: inherit !important; -webkit-text-fill-color: currentcolor !important; }
    #tinymce .explanation {
      color: ${isDark ? '#a1a1aa' : '#4b5563'} !important;
      -webkit-text-fill-color: currentcolor !important;
    }

    #tinymce p { margin: 0 0 1.5rem; }
    #tinymce :is(h1, h2, h3, h4, h5, h6) { margin: 2rem 0 1rem; font-weight: 700; line-height: 1.3; }
    ${headingSizes}

    #tinymce a { text-decoration: underline; font-style: italic; }
    #tinymce :is(strong, b) { font-weight: 700; }
    #tinymce :is(em, i) { font-style: italic; }
    #tinymce u { text-decoration: underline; }
    #tinymce :is(s, strike, del) { text-decoration: line-through; opacity: 0.7; }

    #tinymce blockquote {
      margin: 1.5rem 0;
      padding: 1rem 1.5rem;
      border: 0;
      border-left: 0.25rem solid ${theme.quote};
      border-radius: 0.25rem;
      font-style: italic;
    }

    #tinymce :is(ul, ol) { margin: 0 0 1.5rem 2rem; padding-left: 1.5rem; }
    #tinymce ul { list-style-type: disc; }
    #tinymce ol { list-style-type: decimal; }
    #tinymce li { margin: 0 0 0.5rem; padding-left: 0.25rem; line-height: 1.7; }

    #tinymce hr { height: 0; margin: 2rem 0; border: 0; border-top: 1px solid #d1d5db; }

    #tinymce img {
      display: block;
      max-width: 100%;
      height: auto;
      border-radius: 0.5rem;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    }

    #tinymce :is(iframe, .mce-preview-object) {
      display: block !important;
      width: 100% !important;
      max-width: 48rem;
      height: auto !important;
      aspect-ratio: 16 / 9;
      margin: 0 auto 1.5rem;
      border: 0;
      border-radius: 0.5rem;
    }
    #tinymce .mce-preview-object { position: relative; }
    #tinymce .mce-preview-object iframe {
      position: absolute;
      inset: 0;
      width: 100% !important;
      height: 100% !important;
      margin: 0;
    }

    #tinymce table { border-collapse: collapse; }
    #tinymce :is(th, td) { padding: 0; border: 0; }
    #tinymce th { font-weight: 700; }

    #tinymce :is(code, pre) { margin: 0; padding: 0; background: none; border-radius: 0; }

    #tinymce .note-reference {
      position: relative;
      display: inline-block;
      cursor: pointer;
      border-bottom: 1px dotted rgba(${theme.note}, 0.6);
      transition: all 0.2s ease;
    }
    #tinymce .note-reference:hover {
      background-color: rgba(${theme.note}, 0.1);
      border-bottom-color: rgba(${theme.note}, 1);
    }
    #tinymce .note-reference::after { content: '📝'; font-size: 0.7em; margin-left: 2px; opacity: 0.7; }

    ::selection { background: rgba(${theme.note}, 0.3); }
  `;
};

const applyEditorContentStyles = (editor, isDark = prefersDarkTheme()) => {
  const doc = editor.getDoc();
  if (!doc) return;

  if (!doc.querySelector('link[data-reader-fonts]')) {
    const fonts = doc.createElement('link');
    fonts.rel = 'stylesheet';
    fonts.href = READER_FONTS_URL;
    fonts.setAttribute('data-reader-fonts', 'true');
    doc.head.appendChild(fonts);
  }

  doc.querySelector('style[data-tinymce-theme]')?.remove();
  const style = doc.createElement('style');
  style.setAttribute('data-tinymce-theme', 'true');
  style.textContent = editorContentCss(isDark);
  doc.head.appendChild(style);
};

// mode_toggler.js calls this when the site theme changes.
window.applyEditorContentTheme = (isDark) => {
  if (typeof tinymce === 'undefined') return;
  tinymce.get().forEach((editor) => applyEditorContentStyles(editor, isDark));
};

// AI answers copied with the chat's copy button arrive as plain-text Markdown. Two of these signals
// make a paste "look like Markdown"; one alone (a lone `**` or `---`) is too common in ordinary text.
const MARKDOWN_SIGNALS = [
  /\*\*[^*\n]+\*\*/,
  /^#{1,6}[ \t]+\S/m,
  /\[\^[^\]\s]+\]/,
  /^[ \t]*(?:-{3,}|\*{3,}|_{3,}|\*[ \t]+\*[ \t]+\*)[ \t]*$/m
];

const looksLikeMarkdown = (text) => MARKDOWN_SIGNALS.filter((signal) => signal.test(text)).length >= 2;

const convertMarkdown = async (url, markdown) => {
  const token = document.querySelector('meta[name="csrf-token"]')?.content;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json', ...(token && { 'X-CSRF-Token': token }) },
    body: JSON.stringify({ markdown })
  });
  let data = {};
  try { data = await response.json(); } catch (_error) { data = {}; }
  if (!response.ok || typeof data.html !== 'string') throw new Error(data.error || `HTTP ${response.status}`);
  return data;
};

const insertConverted = (editor, { html, changes }) => {
  editor.insertContent(html);
  if (changes?.length) {
    editor.notificationManager.open({ text: `Під час вставки прибрано: ${changes.join('; ')}`, type: 'warning', timeout: 10000 });
  }
};

const convertAndInsert = async (editor, api, url, markdown) => {
  api.block('Перетворюю…');
  try {
    const data = await convertMarkdown(url, markdown);
    api.close();
    insertConverted(editor, data);
  } catch (error) {
    api.unblock();
    editor.notificationManager.open({ text: error.message || 'Не вдалося перетворити текст', type: 'error', timeout: 8000 });
  }
};

const openMarkdownImportDialog = (editor, url) => {
  editor.windowManager.open({
    title: 'Вставити Markdown',
    size: 'large',
    body: {
      type: 'panel',
      items: [
        {
          type: 'htmlpanel',
          html: '<p>Вставте текст із розміткою Markdown. Жирний (**текст**), курсив (*текст*), заголовки (#), розриви сцен (***) і примітки ([^1]) стануть форматуванням редактора.</p>'
        },
        { type: 'textarea', name: 'markdown', placeholder: 'Текст у форматі Markdown', maximized: true }
      ]
    },
    buttons: [
      { type: 'cancel', text: 'Скасувати' },
      { type: 'submit', text: 'Вставити', primary: true }
    ],
    onSubmit: (api) => {
      const { markdown } = api.getData();
      if (!markdown.trim()) return;
      convertAndInsert(editor, api, url, markdown);
    }
  });
};

const offerMarkdownConversion = (editor, url, text) => {
  editor.windowManager.open({
    title: 'Схоже на розмітку Markdown',
    body: {
      type: 'panel',
      items: [{
        type: 'htmlpanel',
        html: '<p>У тексті є розмітка Markdown (**жирний**, заголовки, *** чи примітки [^1]). Перетворити її на форматування редактора?</p>'
      }]
    },
    buttons: [
      { type: 'custom', name: 'as_is', text: 'Вставити як є' },
      { type: 'submit', text: 'Перетворити', primary: true }
    ],
    onAction: (api, details) => {
      if (details.name !== 'as_is') return;
      api.close();
      editor.execCommand('mceInsertClipboardContent', false, { text });
    },
    onSubmit: (api) => convertAndInsert(editor, api, url, text)
  });
};

// Only forms that opt in (the chapter form) get the Markdown import button and the paste check.
const setupMarkdownImport = (editor) => {
  const url = editor.getElement()?.dataset.markdownImportUrl;
  if (!url) return;

  editor.ui.registry.addIcon('markdown-import', '<svg width="24" height="24" viewBox="0 0 24 24"><path fill-rule="evenodd" d="M3 6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6zm2 0v12h14V6H5z"/><path d="M5.5 15.5v-7h1.8L9 10.8l1.7-2.3h1.8v7h-1.8v-4.2L9 13.6l-1.7-2.3v4.2z"/><path d="M15.75 8.5h1.5V12h1.25l-2 3.5-2-3.5h1.25z"/></svg>');
  editor.ui.registry.addButton('markdownimport', {
    icon: 'markdown-import',
    tooltip: 'Вставити Markdown',
    onAction: () => openMarkdownImportDialog(editor, url)
  });

  editor.on('paste', (event) => {
    const types = Array.from(event.clipboardData?.types || []);
    if (types.includes('text/html') || types.includes('Files')) return;

    const text = event.clipboardData?.getData('text/plain') || '';
    if (!looksLikeMarkdown(text)) return;

    event.preventDefault();
    offerMarkdownConversion(editor, url, text);
  });
};

const base64Key = (base64) => `${base64.length}:${base64.slice(-32)}`;
const dataUriBase64 = (src) => src.split(';base64,')[1] || '';

// Inline images already in the body stay inline for the after-save job, so opening an old
// chapter neither uploads its images nor marks the editor as changed. The parser turns
// data URIs into blob: URIs, so images are matched by their base64 in the blob cache.
const keepExistingInlineImages = (editor) => {
  const textarea = editor.getElement();
  if (!textarea?.dataset.imageUploadUrl) return;

  const html = new DOMParser().parseFromString(textarea.value, 'text/html');
  const existing = new Set(
    Array.from(html.querySelectorAll('img[src^="data:"]'), (img) => base64Key(dataUriBase64(img.getAttribute('src'))))
  );
  if (existing.size === 0) return;

  editor.on('PreInit', () => {
    const { blobCache } = editor.editorUpload;
    editor.editorUpload.addFilter((img) => {
      const base64 = blobCache.getByUri(img.src)?.base64() ?? dataUriBase64(img.src);
      return !existing.has(base64Key(base64));
    });
  });
};

// TinyMCE's align menu always includes justify. The chapter editor keeps left, center, and right.
const setupReaderAlign = (editor) => {
  const choices = [
    ['Left', 'align-left', 'JustifyLeft', 'alignleft'],
    ['Center', 'align-center', 'JustifyCenter', 'aligncenter'],
    ['Right', 'align-right', 'JustifyRight', 'alignright']
  ];

  editor.ui.registry.addMenuButton('readeralign', {
    icon: 'align-left',
    tooltip: 'Align',
    onSetup: (api) => {
      const update = () => {
        const active = choices.find(([, , , format]) => editor.formatter.match(format));
        api.setIcon(active ? active[1] : 'align-left');
      };
      editor.on('NodeChange', update);
      update();
      return () => editor.off('NodeChange', update);
    },
    fetch: (callback) => {
      callback(choices.map(([text, icon, command, format]) => ({
        type: 'togglemenuitem',
        text,
        icon,
        onAction: () => editor.execCommand(command),
        onSetup: (api) => {
          const update = () => api.setActive(!!editor.formatter.match(format));
          editor.on('NodeChange', update);
          update();
          return () => editor.off('NodeChange', update);
        }
      })));
    }
  });
};

// A heading is a block, so TinyMCE would restyle the whole paragraph. A partial selection is split off first.
const BLOCK_SELECTION_FORMATS = new Set(['p', 'h2', 'h3', 'h4', 'blockquote']);
const SPLITTABLE_BLOCKS = new Set(['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote']);

const isBlankHtml = (html) => {
  if (/<(?:img|iframe|hr)\b/i.test(html)) return false;
  return html
    .replace(/<br\s*\/?>/gi, '')
    .replace(/&nbsp;|&#160;/gi, '')
    .replace(/<[^>]*>/g, '')
    .replace(/[\s\u00a0\uFEFF]/g, '') === '';
};

const htmlFromRange = (editor, range) => {
  const holder = editor.dom.create('div');
  holder.appendChild(range.cloneContents());
  return holder.innerHTML;
};

const trimEdgeBreaks = (html, edge) => (
  edge === 'start'
    ? html.replace(/^(?:\s*<br\s*\/?>)+/gi, '')
    : html.replace(/(?:<br\s*\/?>\s*)+$/gi, '')
);

const stripEmptyInlines = (html) => {
  let next = html;
  let previous;
  do {
    previous = next;
    next = next.replace(/<(strong|b|em|i|u|s|span|a)\b[^>]*>(?:\s|&nbsp;)*<\/\1>/gi, '');
  } while (next !== previous);
  return next;
};

const elementFullySelected = (element, range) => {
  const doc = element.ownerDocument;
  const before = doc.createRange();
  before.setStartBefore(element);
  before.setEnd(range.startContainer, range.startOffset);
  const after = doc.createRange();
  after.setStart(range.endContainer, range.endOffset);
  after.setEndAfter(element);
  const blank = (probe) => probe.toString().replace(/[\s\u00a0]/g, '') === '';
  try {
    return blank(before) && blank(after);
  } catch (_error) {
    return false;
  }
};

const selectedHtml = (editor, range, block) => {
  let node = range.commonAncestorContainer;
  if (node.nodeType === 3) node = node.parentNode;
  let covered = null;
  while (node && node !== block && !editor.dom.isBlock(node)) {
    if (elementFullySelected(node, range)) covered = node;
    node = node.parentNode;
  }
  return covered ? covered.outerHTML : editor.selection.getContent();
};

const blockPiece = (tag, html) => {
  if (isBlankHtml(html)) return '';
  if (tag === 'blockquote') return `<blockquote><p>${html}</p></blockquote>`;
  return `<${tag}>${html}</${tag}>`;
};

const applyBlockToPartialSelection = (editor, format) => {
  if (!BLOCK_SELECTION_FORMATS.has(format) || editor.selection.isCollapsed()) return false;

  const range = editor.selection.getRng();
  const startBlock = editor.dom.getParent(range.startContainer, editor.dom.isBlock);
  const endBlock = editor.dom.getParent(range.endContainer, editor.dom.isBlock);
  if (!startBlock || startBlock !== endBlock || startBlock === editor.getBody()) return false;

  const tag = startBlock.nodeName.toLowerCase();
  if (!SPLITTABLE_BLOCKS.has(tag) || tag === format) return false;
  if (format === 'blockquote' && editor.dom.getParent(startBlock, 'blockquote')) return false;

  const selected = selectedHtml(editor, range, startBlock);
  if (isBlankHtml(selected)) return false;

  let beforeHtml;
  let afterHtml;
  try {
    const beforeRange = editor.dom.createRng();
    beforeRange.setStart(startBlock, 0);
    beforeRange.setEnd(range.startContainer, range.startOffset);
    const afterRange = editor.dom.createRng();
    afterRange.setStart(range.endContainer, range.endOffset);
    afterRange.setEnd(startBlock, startBlock.childNodes.length);
    beforeHtml = stripEmptyInlines(trimEdgeBreaks(htmlFromRange(editor, beforeRange), 'end'));
    afterHtml = stripEmptyInlines(trimEdgeBreaks(htmlFromRange(editor, afterRange), 'start'));
  } catch (_error) {
    return false;
  }
  if (isBlankHtml(beforeHtml) && isBlankHtml(afterHtml)) return false;

  const id = editor.dom.uniqueId('blocksplit');
  const middle = format === 'blockquote'
    ? `<blockquote id="${id}"><p>${selected}</p></blockquote>`
    : `<${format} id="${id}">${selected}</${format}>`;

  editor.dom.setOuterHTML(startBlock, `${blockPiece(tag, beforeHtml)}${middle}${blockPiece(tag, afterHtml)}`);
  const created = editor.dom.get(id);
  if (created) {
    editor.selection.select(created, true);
    editor.selection.collapse(false);
    created.removeAttribute('id');
  }
  editor.nodeChanged();
  return true;
};

const setupBlockSelection = (editor) => {
  editor.on('BeforeExecCommand', (event) => {
    if (event.command !== 'mceToggleFormat') return;
    if (!applyBlockToPartialSelection(editor, event.value)) return;
    event.preventDefault();
  });
};

const EXPLANATION_CLASS = 'explanation';
// Kept in step with UserContent::LinkScrubber::CONTENT_CLASSES.
const CONTENT_CLASSES = new Set(['note-reference', EXPLANATION_CLASS]);

const stripForeignClasses = (element) => {
  if (!element.hasAttribute('class')) return;

  const kept = element.getAttribute('class').split(/\s+/).filter((name) => CONTENT_CLASSES.has(name));
  if (kept.length) element.setAttribute('class', kept.join(' '));
  else element.removeAttribute('class');
};

const TEXT_COLOR_PROPERTIES = new Set(['color', '-webkit-text-fill-color']);

const styleDeclarations = (style) => (style || '').split(';').map((part) => part.trim()).filter(Boolean);

const isTextColor = (declaration) => TEXT_COLOR_PROPERTIES.has(declaration.split(':')[0].trim().toLowerCase());

const addExplanationClass = (element) => {
  const classes = element.getAttribute('class')?.split(/\s+/).filter(Boolean) || [];
  if (classes.includes(EXPLANATION_CLASS)) return;
  element.setAttribute('class', [...classes, EXPLANATION_CLASS].join(' '));
};

// Same rules as UserContent::ExplanationNotes. Runs on the editor's first load so a save
// stores the class. Paste still drops color and does not become a note.
const promoteExplanations = (html) => {
  if (!/color\s*:|<\s*(?:em|i)\b/i.test(html)) return html;

  const root = document.createElement('div');
  root.innerHTML = html;
  let changed = false;

  root.querySelectorAll('[style]').forEach((element) => {
    const kept = [];
    let colored = false;
    styleDeclarations(element.getAttribute('style')).forEach((declaration) => {
      if (isTextColor(declaration)) colored = true;
      else kept.push(declaration);
    });
    if (!colored) return;

    addExplanationClass(element);
    if (kept.length) element.setAttribute('style', kept.join('; '));
    else element.removeAttribute('style');
    changed = true;
  });

  root.querySelectorAll('em, i').forEach((element) => {
    if (element.classList.contains(EXPLANATION_CLASS)) return;
    const parent = element.parentElement;
    if (!parent || parent.tagName !== 'P') return;
    if (parent.querySelectorAll(':scope > em, :scope > i').length !== 1) return;
    if ([...parent.children].some((child) => child !== element)) return;
    if (!/^\(\d+\)/.test(parent.textContent.replace(/\s+/g, ' ').trim())) return;

    addExplanationClass(element);
    changed = true;
  });

  return changed ? root.innerHTML : html;
};

const replaceTypedTail = (editor, node, offset, length, replacement) => {
  const start = offset - length;
  if (start < 0) return;

  editor.undoManager.transact(() => {
    node.replaceData(start, length, replacement);
    editor.selection.setCursorLocation(node, start + replacement.length);
  });
};

// Typed replacements only. Saved chapters are left alone. `--` after a space or at the
// start of a line, `...`, and straight quotes. `# ` headings are text_patterns.
const setupTypography = (editor) => {
  editor.on('keyup', (event) => {
    if (event.key !== '-' && event.key !== '.' && event.key !== '"') return;

    const range = editor.selection.getRng();
    if (!range.collapsed || range.startContainer.nodeType !== Node.TEXT_NODE) return;

    const node = range.startContainer;
    const offset = range.startOffset;
    const before = node.data.slice(0, offset);

    if (/(?:^|[\s\u00A0])--$/.test(before)) {
      replaceTypedTail(editor, node, offset, 2, '—');
      return;
    }
    if (before.endsWith('...')) {
      replaceTypedTail(editor, node, offset, 3, '…');
      return;
    }
    if (before.endsWith('"')) {
      const lead = before.slice(0, -1);
      const opening = lead.length === 0 || /[\s\u00A0([{\-—–«]$/.test(lead);
      replaceTypedTail(editor, node, offset, 1, opening ? '«' : '»');
    }
  });
};

const setupExplanation = (editor) => {
  editor.on('PreInit', () => {
    editor.formatter.register('explanation', {
      inline: 'span',
      classes: EXPLANATION_CLASS,
      exact: true
    });
  });

  editor.ui.registry.addIcon(
    'explanation-icon',
    '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M5 18h14v1.5H5V18zm1.2-2.2 3.1-9.3h1.5l3.1 9.3h-1.6l-.7-2.2H8.5l-.7 2.2H6.2zm2.6-3.6h2.5L10.1 8.4 8.8 12.2z" fill="currentColor"/></svg>'
  );

  editor.ui.registry.addToggleButton('explanation', {
    icon: 'explanation-icon',
    tooltip: 'Explanation',
    onAction: () => {
      if (!editor.selection.getContent({ format: 'text' }).trim()) {
        editor.windowManager.alert(editor.translate('Select text to mark as an explanation'));
        return;
      }
      editor.formatter.toggle('explanation');
    },
    onSetup: (api) => {
      const sync = () => api.setActive(editor.formatter.match('explanation'));
      editor.on('NodeChange', sync);
      return () => editor.off('NodeChange', sync);
    }
  });
};

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
    'Block': 'Тип блоку',
    'Blocks': 'Блоки',
    'Paragraph': 'Абзац',
    'Heading 2': 'Заголовок 2',
    'Heading 3': 'Заголовок 3',
    'Heading 4': 'Заголовок 4',
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
    'Background color': 'Колір тла',
    'Insert/edit tooltip': 'Вставити/редагувати примітку',
    'Tooltip text': 'Текст примітки',
    'Remove tooltip': 'Видалити примітку',
    'Please select some text first': 'Спершу виділіть текст для примітки',
    'Upload': 'Завантажити',
    'Drop an image here': 'Перетягніть зображення сюди',
    'Browse for an image': 'Вибрати зображення',
    'Browse files': 'Вибрати файл',
    'Failed to upload image: {0}': 'Не вдалося завантажити зображення: {0}',
    'Insert YouTube video': 'Вставити ролик YouTube',
    'YouTube URL': 'Посилання на ролик',
    'Only a YouTube link can be embedded': 'Можна вставити лише посилання на ролик YouTube',
    'Removed an embed that is not a YouTube video': 'Прибрано вбудовану сторінку: можна лише ролик YouTube',
    'Find': 'Знайти',
    'Previous': 'Попереднє',
    'Next': 'Наступне',
    'Replace': 'Замінити',
    'Replace with': 'Замінити на',
    'Replace all': 'Замінити все',
    'Find and Replace': 'Пошук і заміна',
    'Find and replace': 'Пошук і заміна',
    'Find and replace...': 'Пошук і заміна...',
    'Match case': 'Враховувати регістр',
    'Find whole words only': 'Лише цілі слова',
    'Find in selection': 'Шукати у виділеному',
    'Could not find the specified string.': 'Не вдалося знайти цей текст.',
    'Preferences': 'Параметри',
    'Explanation': 'Пояснення',
    'Select text to mark as an explanation': 'Спершу виділіть текст для пояснення'
  });
  tinymce.init({
    ...imageUploadOptions(textarea),
    license_key: 'gpl',
    language: 'uk',
    selector: 'textarea',
    height: 500,
    toolbar_mode: 'wrap',
    plugins: [
      'autosave',
      'image',
      'link',
      'lists',
      'media',
      'quickbars',
      'searchreplace',
      'wordcount'
    ],
    menubar: false,
    // No Heading 1: the chapter title is its own field, and the API sanitizer renames h1 to h2.
    block_formats: 'Paragraph=p;Heading 2=h2;Heading 3=h3;Heading 4=h4;Blockquote=blockquote',
    // The default preview copies the editor canvas color. On a dark theme that paints each row black.
    preview_styles: 'font-size font-weight font-style text-decoration color',
    // Chapter and publication editors share this toolbar. Font, size, line-height, color, indent, and justify stay off it.
    toolbar: `${textarea.dataset.markdownImportUrl ? 'markdownimport | ' : ''}undo redo | blocks | bold italic underline strikethrough explanation | link tooltip | readeralign | removeformat | image media | hr | searchreplace wordcount`,
    media_alt_source: false,
    media_poster: false,
    media_url_resolver: (data) => {
      const src = youtubeEmbedSrc(data.url);
      if (!src) return Promise.reject({ msg: 'Можна вставити лише посилання на ролик YouTube' });

      return Promise.resolve({
        html: `<iframe src="${escapeAttr(src)}" width="560" height="314" frameborder="0" allowfullscreen="allowfullscreen"></iframe>`
      });
    },
    quickbars_insert_toolbar: 'image media',
    quickbars_selection_toolbar: 'bold italic underline strikethrough | blockquote quicklink tooltip',
    contextmenu: false,
    statusbar: false,
    // Enter starts a paragraph. Shift+Enter keeps a line break. Paste and Markdown import do not use this.
    newline_behavior: 'block',
    text_patterns: [
      { start: '*', end: '*', format: 'italic' },
      { start: '**', end: '**', format: 'bold' },
      { start: '###', format: 'h4', trigger: 'space' },
      { start: '##', format: 'h3', trigger: 'space' },
      { start: '#', format: 'h2', trigger: 'space' },
      { start: '1. ', cmd: 'InsertOrderedList' },
      { start: '* ', cmd: 'InsertUnorderedList' },
      { start: '- ', cmd: 'InsertUnorderedList' }
    ],
    link_title: false,
    // GDocs/WebKit paste: drop background, color, family, size, and line-height.
    // Bold, italic, and underline stay. Stored HTML is not rewritten.
    paste_webkit_styles: 'font-weight font-style text-decoration',
    paste_postprocess: function(editor, args) {
      const stripNonInheritedPasteStyles = function(styleStr) {
        if (!styleStr || !styleStr.trim()) return null;
        const dropName = function(name) {
          if (name.indexOf('background') === 0) return true;
          if (name === 'color' || name === 'text-decoration-color') return true;
          if (name === '-webkit-text-fill-color') return true;
          // font shorthand sets family and size, so it goes with those four.
          if (name === 'font' || name === 'font-family' || name === 'font-size' || name === 'line-height') return true;
          return false;
        };
        const next = styleStr
          .split(';')
          .map(function(s) { return s.trim(); })
          .filter(Boolean)
          .filter(function(decl) {
            const prop = decl.split(':')[0];
            if (!prop) return true;
            return !dropName(prop.trim().toLowerCase());
          })
          .join('; ');
        return next.length ? next : null;
      };

      const walk = function(node) {
        if (node.nodeType !== 1) return;
        const el = node;
        stripForeignClasses(el);
        if (el.hasAttribute('style')) {
          const cleaned = stripNonInheritedPasteStyles(el.getAttribute('style'));
          if (cleaned) el.setAttribute('style', cleaned);
          else el.removeAttribute('style');
        }
        if (el.hasAttribute('data-mce-style')) {
          const cleanedMce = stripNonInheritedPasteStyles(el.getAttribute('data-mce-style'));
          if (cleanedMce) el.setAttribute('data-mce-style', cleanedMce);
          else el.removeAttribute('data-mce-style');
        }
        for (let i = 0; i < el.children.length; i++) {
          walk(el.children[i]);
        }
      };

      walk(args.node);
    },
    extended_valid_elements: 'span[class|data-note|data-note-id|style]',
    valid_children: '+body[style],+span[data-note]',
    setup: function(editor) {
      keepExistingInlineImages(editor);
      setupMarkdownImport(editor);
      setupReaderAlign(editor);
      setupBlockSelection(editor);
      setupTypography(editor);
      setupExplanation(editor);

      editor.on('BeforeSetContent', (event) => {
        if (typeof event.content !== 'string') return;
        if (event.initial) event.content = promoteExplanations(event.content);

        const sanitized = sanitizeIframeHtml(event.content);
        if (sanitized.html === event.content) return;

        event.content = sanitized.html;
        if (!sanitized.removed) return;

        const warn = () => editor.notificationManager.open({
          text: editor.translate('Removed an embed that is not a YouTube video'),
          type: 'warning',
          timeout: 8000
        });
        if (editor.initialized) warn();
        else editor.once('init', warn);
      });

      // Add custom note button
      editor.ui.registry.addIcon('note-icon', '<svg width="24" height="24" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7.556 8.5h8m-8 3.5H12m7.111-7H4.89a.896.896 0 0 0-.629.256.868.868 0 0 0-.26.619v9.25c0 .232.094.455.26.619A.896.896 0 0 0 4.89 16H9l3 4 3-4h4.111a.896.896 0 0 0 .629-.256.868.868 0 0 0 .26-.619v-9.25a.868.868 0 0 0-.26-.619.896.896 0 0 0-.63-.256Z"/></svg>');

      editor.ui.registry.addButton('tooltip', {
        icon: 'note-icon',
        tooltip: editor.translate('Insert/edit tooltip'),
        onAction: function() {
          const selectedText = editor.selection.getContent({ format: 'text' });
          const selectedNode = editor.selection.getNode();
          const existingNote = selectedNode.getAttribute && selectedNode.getAttribute('data-note');

          if (!selectedText && !existingNote) {
            editor.windowManager.alert(editor.translate('Please select some text first'));
            return;
          }

          editor.windowManager.open({
            title: editor.translate('Insert/edit tooltip'),
            body: {
              type: 'panel',
              items: [
                {
                  type: 'input',
                  name: 'noteText',
                  label: editor.translate('Tooltip text'),
                  placeholder: editor.translate('Tooltip text')
                }
              ]
            },
            initialData: {
              noteText: existingNote || ''
            },
            buttons: [
              {
                type: 'cancel',
                text: editor.translate('Cancel')
              },
              {
                type: 'submit',
                text: editor.translate('Save'),
                primary: true
              }
            ],
            onSubmit: function(api) {
              const data = api.getData();
              const noteText = data.noteText.trim();

              if (noteText) {
                const content = selectedText || selectedNode.textContent;
                const noteId = 'note-' + Date.now();
                const html = `<span class="note-reference" data-note="${noteText.replace(/"/g, '&quot;')}" data-note-id="${noteId}">${content}</span>`;
                editor.selection.setContent(html);
              }

              api.close();
            }
          });
        }
      });

      // Cmd/Ctrl+S inside the iframe does not bubble to the Stimulus hotkey.
      editor.addShortcut('Meta+S', 'Save draft', function() {
        document.querySelector('[data-draft-hotkey-target="draftSubmit"]')?.click();
      });

      editor.on('init', function() {
        // The media plugin's dialog accepts arbitrary embed HTML. Replace that command with a YouTube URL field.
        editor.addCommand('mceMedia', () => openYoutubeDialog(editor));

        const form = editor.getElement()?.form;
        if (form) {
          form.addEventListener('submit', () => editor.save(), { capture: true });
        }

        applyEditorContentStyles(editor);
        
        // Style the TinyMCE editor header/toolbar
        const editorContainer = editor.getContainer();
        const header = editorContainer.querySelector('.tox-editor-header');
        if (header) {
          const isDark = localStorage.getItem('color-theme') === 'dark' ||
            (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches);
          
          const headerStyle = document.createElement('style');
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
            
            /* The note icon is a stroke. The quickbar sits outside the header, so currentColor stays dark. */
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
        }
      });
    }
  });
};

document.addEventListener('turbo:load', initializeTinymce);
document.addEventListener('turbo:render', initializeTinymce);

// Both Зберегти (intent=draft) and Надіслати (intent=publish) are type=submit,
// so turbo:submit-start runs triggerSave for either button.
function syncTinymceBeforeTurboSubmit(event) {
  if (typeof tinymce === 'undefined') return;

  const form = event.detail?.formSubmission?.formElement;
  if (!form?.querySelector?.('textarea.tinymce')) return;

  tinymce.triggerSave();
}

document.addEventListener('turbo:submit-start', syncTinymceBeforeTurboSubmit);
