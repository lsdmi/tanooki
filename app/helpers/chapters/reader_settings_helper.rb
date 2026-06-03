# frozen_string_literal: true

module Chapters
  # Font choices for the immersive chapter reader (Google Fonts, Cyrillic / Ukrainian).
  module ReaderSettingsHelper
    READER_FONT_SPECS = [
      { id: 'golos-text', label_key: 'golos_text' },
      { id: 'literata', label_key: 'literata' },
      { id: 'spectral', label_key: 'spectral' },
      { id: 'eb-garamond', label_key: 'eb_garamond' },
      { id: 'pt-serif', label_key: 'pt_serif' }
    ].freeze

    def reader_font_choices
      READER_FONT_SPECS.map do |font|
        font.merge(label: I18n.t("chapters.reader_settings.fonts.#{font[:label_key]}"))
      end
    end
  end
end
