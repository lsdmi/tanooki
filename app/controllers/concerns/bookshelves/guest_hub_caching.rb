# frozen_string_literal: true

module Bookshelves
  # Private browser Cache-Control / validators for guest HTML bookshelves#index.
  module GuestHubCaching
    private

    def serve_fresh_guest_hub?
      return false unless guest_hub_request?

      apply_guest_hub_http_cache
      return false unless request.fresh?(response)

      head :not_modified
      true
    end

    def set_guest_hub_cache_headers
      return unless guest_hub_http_cacheable?

      apply_guest_hub_http_cache
    end

    def apply_guest_hub_http_cache
      response.etag = guest_hub_etag
      expires_in Fictions::ShowCacheHelper::GUEST_HTTP_EXPIRY, public: false, must_revalidate: true
    end

    def guest_hub_request?
      request.get? &&
        request.format.symbol == :html &&
        current_user.nil? &&
        request.query_string.blank? &&
        turbo_frame_request_id.blank?
    end

    def guest_hub_http_cacheable?
      guest_hub_request? && (response.successful? || response.status == 304)
    end

    def guest_hub_etag
      etag = guest_hub_etag_parts
      etag << current_content_filter.fingerprint if current_content_filter.active?
      etag
    end

    def guest_hub_etag_parts
      [
        'bookshelves/index/v1',
        I18n.locale,
        cookies[:color_theme].presence || 'light',
        Bookshelf.maximum(:updated_at),
        Bookshelf.count,
        BookshelfFiction.maximum(:updated_at),
        BookshelfFiction.count
      ]
    end
  end
end
