# frozen_string_literal: true

module FictionTags
  # Canonical form for user-typed tag names and the slug used to dedupe them.
  # Case is preserved for display (ЛітРПГ); names differing only in case, apostrophe
  # style or ё/е collapse to the same slug and therefore to the same tag.
  module Normalizer
    APOSTROPHES = /['`ʼ‘´]/
    LEADING_HASHES = /\A#+/

    module_function

    def name(value)
      value.to_s
           .unicode_normalize(:nfc)
           .gsub(APOSTROPHES, '’')
           .tr('ёЁ', 'еЕ')
           .squish
           .sub(LEADING_HASHES, '')
           .strip
    end

    def slug(value)
      I18n.with_locale(:uk) { name(value).parameterize }
    end

    def unique_names(values)
      Array(values).map { |value| name(value) }
                   .reject { |value| slug(value).blank? }
                   .uniq { |value| slug(value) }
    end
  end
end
