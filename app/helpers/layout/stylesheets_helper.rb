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
      optional_stylesheets.filter_map { |sheet, required| sheet if required }
    end

    def optional_stylesheets
      [
        ['pagy', requires_pagy_styles?],
        ['slimselect', requires_slimselect_styles?],
        ['actiontext', requires_actiontext_styles?],
        ['adult_content_disclaimer', requires_adult_content_disclaimer_styles?],
        ['chapters_reader', requires_chapters_reader_styles?],
        ['sweetal2', requires_sweetalert_styles?],
        ['flatpickr_overrides', requires_flatpickr_styles?]
      ]
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

    def requires_adult_content_disclaimer_styles?
      fiction = stylesheet_context_fiction
      fiction.present? && show_adult_content_disclaimer?(fiction)
    end

    def requires_chapters_reader_styles?
      chapters_show_page? || fiction_show_with_reader_support_card?
    end

    def fiction_show_with_reader_support_card?
      fiction = stylesheet_context_fiction
      controller_name == 'fictions' && action_name == 'show' && fiction.present? && fiction_reader_support?(fiction)
    end

    def stylesheet_context_fiction
      controller.view_assigns['fiction'] || controller.view_assigns['chapter']&.fiction
    end

    def requires_sweetalert_styles?
      controller_name.in?(SWEETALERT_CONTROLLER_NAMES)
    end

    def requires_flatpickr_styles?
      controller_name == 'chapters' && %w[new edit create update].include?(action_name)
    end
  end
end
