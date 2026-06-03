# frozen_string_literal: true

module Layout
  # Controller/action predicates for layout assets and page-specific UI.
  module PageContextHelper
    def chapters_show_page?
      controller_name.to_sym == :chapters && action_name.to_sym == :show
    end

    # Chapter reader: hide site navbar/footer; use reader chrome + minimal copyright.
    def immersive_reader_layout?
      chapters_show_page?
    end

    def requires_font?
      (controller_name.to_sym == :tales && action_name.to_sym == :show) ||
        chapters_show_page?
    end

    def requires_legacy_font_toggler?
      controller_name.to_sym == :tales && action_name.to_sym == :show
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

    def requires_tinymce?
      (controller_name == 'publications' && %w[new edit create update].include?(action_name)) ||
        (controller_name == 'chapters' && %w[new edit create update].include?(action_name))
    end

    def requires_sweetalert?
      controller_name.in?(%w[studio readings])
    end

    def genre_show_page?
      controller_path == 'fictions/genres' && action_name == 'show'
    end
  end
end
