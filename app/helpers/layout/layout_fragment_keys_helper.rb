# frozen_string_literal: true

module Layout
  # Cache keys for shared layout fragments (navbar, footer, ads).
  module LayoutFragmentKeysHelper
    def fragment_cache_version_bucket(expires_in = 12.hours)
      Time.current.to_i / expires_in.to_i
    end

    def navbar_fragment_cache_key
      [
        'navbar/v1',
        I18n.locale,
        cookies[:color_theme].presence || 'light',
        current_user&.id || 'guest',
        current_user&.admin? == true,
        fragment_cache_version_bucket(1.hour)
      ]
    end

    def footer_fragment_cache_key
      [
        'footer/v2',
        I18n.locale,
        Time.zone.now.year,
        fragment_cache_version_bucket(12.hours)
      ]
    end

    def advertisement_fragment_cache_key(advertisement)
      [
        'ad/v2',
        advertisement,
        advertisement.cover.blob&.id,
        advertisement.poster.blob&.id
      ]
    end
  end
end
