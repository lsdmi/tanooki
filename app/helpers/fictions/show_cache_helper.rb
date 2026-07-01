# frozen_string_literal: true

module Fictions
  # Fragment and HTTP cache keys for guest fiction#show (Phase 5 TTFB).
  module ShowCacheHelper
    include Layout::LayoutFragmentKeysHelper

    GUEST_FRAGMENT_EXPIRY = 15.minutes
    GUEST_HTTP_EXPIRY = 2.minutes

    def guest_fiction_show_fragment_cacheable?
      current_user.nil?
    end

    def guest_fiction_show_fragment_cache_key(fiction, show_presenter, advertisement)
      [
        'fiction_show/v1/guest',
        fiction,
        show_presenter.order,
        I18n.locale,
        cookies[:color_theme].presence || 'light',
        advertisement&.id,
        adult_content_acknowledged?,
        fragment_cache_version_bucket(GUEST_FRAGMENT_EXPIRY)
      ]
    end

    def guest_fiction_show_fragment_expires_in
      GUEST_FRAGMENT_EXPIRY
    end
  end
end
