# frozen_string_literal: true

module Layout
  # Maps pages to optional stylesheets so global bundles stay lean.
  module StylesheetsHelper
    include AssetRequirementsHelper

    GLOBAL_STYLESHEETS = [].freeze

    FEATURE_STYLESHEETS = [
      ['pagy', :requires_pagy_styles?],
      ['slimselect', :requires_slimselect_styles?],
      ['actiontext', :requires_actiontext_styles?],
      ['chapters_reader', :requires_chapters_reader_styles?],
      ['sweetal2', :requires_sweetalert_styles?],
      ['adsense_slots', :requires_adsense_slots_styles?]
    ].freeze

    def global_stylesheets
      GLOBAL_STYLESHEETS
    end

    def page_stylesheets
      optional_stylesheets.filter_map { |sheet, required| sheet if required }
    end

    def optional_stylesheets
      feature_stylesheets + [
        ['adult_content_disclaimer', requires_adult_content_disclaimer_styles?],
        ['flatpickr_overrides', requires_flatpickr_styles?]
      ]
    end

    private

    def feature_stylesheets
      FEATURE_STYLESHEETS.map { |sheet, predicate| [sheet, public_send(predicate)] }
    end
  end
end
