# frozen_string_literal: true

module Layout
  # Controller/action predicates for layout assets and page-specific UI.
  module PageContextHelper
    include AssetRequirementsHelper

    # Chapter reader: hide site navbar/footer; use reader chrome + minimal copyright.
    def immersive_reader_layout?
      chapters_show_page?
    end

    def reader_google_fonts_stylesheet_url
      # Literata must use a range (400..700), not discrete weights — invalid URLs 400 and break the whole sheet.
      'https://fonts.googleapis.com/css2?' \
        'family=Golos+Text:wght@400;500;600&' \
        'family=Literata:opsz,wght@7..72,400..700&' \
        'family=Spectral:wght@400;500;600&' \
        'family=EB+Garamond:wght@400;500;600&' \
        'family=PT+Serif:wght@400;700&' \
        'display=swap'
    end
  end
end
