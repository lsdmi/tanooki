# frozen_string_literal: true

module Layout
  # Declarative page → asset rules shared by layout JS tags and optional stylesheets.
  module AssetRequirementsHelper
    include Routing::PageContextHelper
    include Layout::AdultContentHelper
    include Chapters::ReaderBottomHelper

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

    TINYMCE_FORM_PAGES = {
      'publications' => %w[new edit create update],
      'chapters' => %w[new edit create update]
    }.freeze

    FLATPICKR_FORM_PAGES = {
      'chapters' => %w[new edit create update]
    }.freeze

    # SweetAlert JS (turbo frame + initializer) vs CSS (sweetal2 bundle) intentionally differ.
    SWEETALERT_JS_CONTROLLER_NAMES = %w[studio readings].freeze
    SWEETALERT_CSS_SHOW_CONTROLLERS = %w[fictions bookshelves scanlators publications].freeze

    ACCORDION_SHOW_CONTROLLERS = %w[fictions chapters].freeze

    FONT_TOGGLER_PAGES = {
      'tales' => %w[show]
    }.freeze

    def requires_tinymce?
      form_page?(TINYMCE_FORM_PAGES)
    end

    def requires_sweetalert_js?
      controller_name.in?(SWEETALERT_JS_CONTROLLER_NAMES)
    end

    def requires_sweetalert_css?
      return true if controller_name.in?(%w[studio readings])

      controller_name.in?(SWEETALERT_CSS_SHOW_CONTROLLERS) && action_name == 'show'
    end

    def requires_note_handler?
      chapters_show_page? || tales_show_page?
    end

    def requires_legacy_font_toggler?
      form_page?(FONT_TOGGLER_PAGES)
    end

    def requires_accordion_js?
      ACCORDION_SHOW_CONTROLLERS.include?(controller_name) && action_name == 'show'
    end

    def requires_pagy_styles?
      PAGY_CONTROLLER_PATHS.include?(controller_path)
    end

    def requires_slimselect_styles?
      form_page?(SLIMSELECT_PAGES)
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

    def requires_flatpickr_styles?
      form_page?(FLATPICKR_FORM_PAGES)
    end

    private

    def form_page?(pages_by_path)
      pages_by_path.fetch(controller_path, []).include?(action_name)
    end

    def fiction_show_with_reader_support_card?
      fiction = stylesheet_context_fiction
      controller_name == 'fictions' && action_name == 'show' && fiction.present? && fiction_reader_support?(fiction)
    end

    def stylesheet_context_fiction
      controller.view_assigns['fiction'] || controller.view_assigns['chapter']&.fiction
    end
  end
end
