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

    SLIMSELECT_FORM_PAGES = {
      'fictions' => %w[new edit create update],
      'chapters' => %w[new edit create update],
      'publications' => %w[new edit create update],
      'scanlators' => %w[new edit create update],
      'bookshelves' => %w[new edit create update],
      'admin/pokemons' => %w[new edit create update]
    }.freeze

    SWEETALERT_PAGES = {
      'studio' => :all,
      'readings' => %w[show]
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

    def requires_reader_google_fonts?
      chapters_show_page?
    end

    def requires_eighteen_notice_styles?
      fiction = stylesheet_context_fiction
      fiction.present? && age_rating_reader_gate?(fiction)
    end

    def requires_flatpickr_styles?
      form_page?(FLATPICKR_FORM_PAGES)
    end

    def requires_pagy_styles?
      stylesheet_view_assigns.any? { |key, value| key.to_s.start_with?('pagy') && value.present? }
    end

    def requires_slimselect_styles?
      form_page?(SLIMSELECT_FORM_PAGES)
    end

    def requires_actiontext_styles?
      chapters_show_page? || tales_show_page?
    end

    def requires_chapters_reader_styles?
      chapters_show_page?
    end

    def requires_sweetalert_styles?
      mapped_page?(SWEETALERT_PAGES)
    end

    def requires_adsense_slots_styles?
      respond_to?(:adsense_adblock_check?) && adsense_adblock_check?
    end

    def flatpickr_stylesheet_url
      FLATPICKR_STYLESHEET_URL
    end

    private

    def form_page?(pages_by_path)
      pages_by_path.fetch(controller_path, []).include?(action_name)
    end

    def mapped_page?(pages_by_path)
      actions = pages_by_path[controller_path]
      return false if actions.blank?

      actions == :all || actions.include?(action_name)
    end

    def stylesheet_context_fiction
      stylesheet_view_assigns['fiction'] || stylesheet_view_assigns['chapter']&.fiction
    end

    def stylesheet_view_assigns
      controller.view_assigns
    end
  end
end
