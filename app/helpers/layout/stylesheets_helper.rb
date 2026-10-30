# frozen_string_literal: true

module Layout
  # Maps pages to optional stylesheets so global bundles stay lean.
  module StylesheetsHelper
    include AssetRequirementsHelper

    GLOBAL_STYLESHEETS = [].freeze

    # Below-fold / late UI: load without blocking first paint (print→all onload trick).
    # Keep sheets that style above-the-fold gates (e.g. adult_content_disclaimer) blocking.
    # pagy: pagination usually below fold; sweetal2: modals after gesture (studio/readings).
    DEFERRED_PAGE_STYLESHEETS = %w[adsense_slots pagy sweetal2].freeze

    FEATURE_STYLESHEETS = [
      ['pagy', :requires_pagy_styles?],
      ['slimselect', :requires_slimselect_styles?],
      ['actiontext', :requires_actiontext_styles?],
      ['chapters_reader', :requires_chapters_reader_styles?],
      ['catalog_storage', :requires_catalog_storage_styles?],
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
        ['adult_content_disclaimer', requires_eighteen_notice_styles?],
        ['flatpickr_overrides', requires_flatpickr_styles?]
      ]
    end

    def deferred_page_stylesheet?(stylesheet)
      DEFERRED_PAGE_STYLESHEETS.include?(stylesheet.to_s)
    end

    # Ad slots sit below the fold on most browse pages; blocking their CSS delays FCP/LCP for ~0.
    def page_stylesheet_link_tags
      safe_join(page_stylesheets.map { |stylesheet| page_stylesheet_link_tag(stylesheet) })
    end

    def page_stylesheet_link_tag(stylesheet)
      if deferred_page_stylesheet?(stylesheet)
        deferred_stylesheet_link_tag(stylesheet)
      else
        stylesheet_link_tag(stylesheet, 'data-turbo-track': 'reload')
      end
    end

    private

    def feature_stylesheets
      FEATURE_STYLESHEETS.map { |sheet, predicate| [sheet, public_send(predicate)] }
    end

    def deferred_stylesheet_link_tag(stylesheet)
      safe_join([deferred_print_stylesheet_link_tag(stylesheet), deferred_stylesheet_noscript_tag(stylesheet)])
    end

    # `dynamic`, not `reload`: onload flips media to "all", and Turbo's reload signature is the
    # whole tag. A mismatch throws the response away and reloads, which drops flashes such as a failed login.
    def deferred_print_stylesheet_link_tag(stylesheet)
      stylesheet_link_tag(stylesheet, media: 'print', onload: "this.media='all'", 'data-turbo-track': 'dynamic')
    end

    def deferred_stylesheet_noscript_tag(stylesheet)
      content_tag(:noscript) { stylesheet_link_tag(stylesheet, media: 'all', 'data-turbo-track': 'reload') }
    end
  end
end
