# frozen_string_literal: true

module Layout
  # Maps pages to optional stylesheets so global bundles stay lean.
  module StylesheetsHelper
    PAGY_CONTROLLER_PATHS = %w[
      tales publications library readings fiction_lists search
      youtube_videos bookshelves scanlators admin/pokemons
      fictions/genres studio translation_requests
    ].freeze

    SLIMSELECT_PAGES = {
      'chapters' => %w[new edit create update],
      'fictions' => %w[new edit create update],
      'publications' => %w[new edit create update],
      'scanlators' => %w[new edit create update],
      'bookshelves' => %w[new edit create update],
      'admin/pokemons' => %w[new edit create update]
    }.freeze

    SWEETALERT_CONTROLLER_NAMES = %w[
      studio readings fictions bookshelves scanlators publications
    ].freeze

    def page_stylesheets
      [].tap do |sheets|
        sheets << 'pagy' if requires_pagy_styles?
        sheets << 'slimselect' if requires_slimselect_styles?
        sheets << 'actiontext' if requires_actiontext_styles?
        sheets << 'adult_content_disclaimer' if requires_adult_content_disclaimer_styles?
        sheets << 'chapters_reader' if requires_chapters_reader_styles?
        sheets << 'sweetal2' if requires_sweetalert_styles?
        sheets << 'flatpickr_overrides' if requires_flatpickr_styles?
      end
    end

    def requires_pagy_styles?
      PAGY_CONTROLLER_PATHS.include?(controller_path)
    end

    def requires_slimselect_styles?
      SLIMSELECT_PAGES.fetch(controller_path, []).include?(action_name)
    end

    def requires_actiontext_styles?
      chapters_show_page? || tales_show_page?
    end

    def tales_show_page?
      controller_name == 'tales' && action_name == 'show'
    end

    def requires_adult_content_disclaimer_styles?
      fiction = @fiction || @chapter&.fiction
      fiction.present? && show_adult_content_disclaimer?(fiction)
    end

    def requires_chapters_reader_styles?
      chapters_show_page? || fiction_show_with_reader_support_card?
    end

    def fiction_show_with_reader_support_card?
      controller_name == 'fictions' && action_name == 'show' && @fiction.present? && fiction_reader_support?(@fiction)
    end

    def requires_sweetalert_styles?
      controller_name.in?(SWEETALERT_CONTROLLER_NAMES)
    end

    def requires_flatpickr_styles?
      controller_name == 'chapters' && %w[new edit create update].include?(action_name)
    end
  end
end
