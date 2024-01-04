# frozen_string_literal: true

Rails.application.config.after_initialize do
  ActionText::ContentHelper.allowed_attributes = Set.new([
    "abbr",
    "alt",
    "cite",
    "class",
    "datetime",
    "height",
    "href",
    "lang",
    "name",
    "src",
    "style",
    "title",
    "width",
    "xml:lang"
  ]).freeze
end
