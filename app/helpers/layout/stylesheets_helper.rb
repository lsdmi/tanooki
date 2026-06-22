# frozen_string_literal: true

module Layout
  # Maps pages to optional stylesheets so global bundles stay lean.
  module StylesheetsHelper
    include AssetRequirementsHelper

    GLOBAL_STYLESHEETS = %w[pagy slimselect actiontext chapters_reader sweetal2].freeze

    def global_stylesheets
      GLOBAL_STYLESHEETS
    end

    def page_stylesheets
      optional_stylesheets.filter_map { |sheet, required| sheet if required }
    end

    def optional_stylesheets
      [
        ['adult_content_disclaimer', requires_adult_content_disclaimer_styles?],
        ['flatpickr_overrides', requires_flatpickr_styles?]
      ]
    end
  end
end
