# frozen_string_literal: true

module Layout
  # Maps pages to optional stylesheets so global bundles stay lean.
  module StylesheetsHelper
    include AssetRequirementsHelper

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
  end
end
