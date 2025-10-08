# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Set allowed tags for ActionText (Rails 8 approach)
  ActionText::ContentHelper.allowed_tags = %w[
    p iframe div span br hr blockquote pre code img
    sub sup mark del ins h1 h2 h3 h4 h5 h6 ul ol li
    b strong i em u small big strike s a table tr td th
    thead tbody caption colgroup col details summary
    figure figcaption time address article aside footer
    header main nav section
  ]

  # Set allowed attributes for ActionText (Rails 8 approach)
  ActionText::ContentHelper.allowed_attributes = [
    'abbr', 'alt', 'cite', 'class', 'datetime', 'height', 'href', 'lang',
    'name', 'src', 'style', 'title', 'width', 'xml:lang', 'frameborder', 'allowfullscreen',
    'loading', 'decoding', 'sizes', 'srcset', 'target', 'rel', 'download', 'hreflang',
    'type', 'media', 'data-*', 'data-tooltip', 'data-note', 'data-note-id', 'aria-*', 'role', 'tabindex', 'accesskey', 'contenteditable',
    'dir', 'hidden', 'id', 'spellcheck', 'translate', 'itemscope', 'itemtype', 'itemprop'
  ]
end
