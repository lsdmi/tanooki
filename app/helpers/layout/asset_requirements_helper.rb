# frozen_string_literal: true

module Layout
  # Declarative page → asset rules shared by layout JS tags and optional stylesheets.
  module AssetRequirementsHelper
    include Routing::PageContextHelper
    include Layout::AdultContentHelper

    TINYMCE_FORM_PAGES = {
      'publications' => %w[new edit create update],
      'chapters' => %w[new edit create update]
    }.freeze

    FLATPICKR_FORM_PAGES = {
      'chapters' => %w[new edit create update]
    }.freeze

    FLATPICKR_STYLESHEET_URL = 'https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/flatpickr.min.css'

    FONT_TOGGLER_PAGES = {
      'tales' => %w[show]
    }.freeze

    def requires_tinymce?
      form_page?(TINYMCE_FORM_PAGES)
    end

    def requires_legacy_font_toggler?
      form_page?(FONT_TOGGLER_PAGES)
    end

    def requires_mode_toggler?
      !chapters_show_page?
    end

    def requires_adult_content_disclaimer_styles?
      fiction = stylesheet_context_fiction
      fiction.present? && show_adult_content_disclaimer?(fiction)
    end

    def requires_flatpickr_styles?
      form_page?(FLATPICKR_FORM_PAGES)
    end

    def flatpickr_stylesheet_url
      FLATPICKR_STYLESHEET_URL
    end

    private

    def form_page?(pages_by_path)
      pages_by_path.fetch(controller_path, []).include?(action_name)
    end

    def stylesheet_context_fiction
      controller.view_assigns['fiction'] || controller.view_assigns['chapter']&.fiction
    end
  end
end
