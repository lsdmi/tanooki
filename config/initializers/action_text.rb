# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Set allowed tags for ActionText (Rails 8 approach)
  ActionText::ContentHelper.allowed_tags = %w[
    p iframe div span br hr blockquote pre code
    sub sup mark del ins h1 h2 h3 h4 h5 h6 ul ol li
  ]

  # Set allowed attributes for ActionText (Rails 8 approach)
  ActionText::ContentHelper.allowed_attributes = [
    'abbr', 'alt', 'cite', 'class', 'datetime', 'height', 'href', 'lang',
    'name', 'src', 'style', 'title', 'width', 'xml:lang', 'frameborder', 'allowfullscreen'
  ]
end
