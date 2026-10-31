# frozen_string_literal: true

module Fictions
  # Private browser Cache-Control / validators for guest HTML fiction_lists#alphabetical.
  module GuestAlphabeticalCaching
    private

    def serve_fresh_guest_alphabetical?
      return false unless guest_alphabetical_request?

      apply_guest_alphabetical_http_cache
      return false unless request.fresh?(response)

      head :not_modified
      true
    end

    def set_guest_alphabetical_cache_headers
      return unless guest_alphabetical_http_cacheable?

      apply_guest_alphabetical_http_cache
    end

    def apply_guest_alphabetical_http_cache
      response.etag = guest_alphabetical_etag
      expires_in Fictions::ShowCacheHelper::GUEST_HTTP_EXPIRY, public: false, must_revalidate: true
    end

    def guest_alphabetical_request?
      request.get? &&
        request.format.symbol == :html &&
        current_user.nil? &&
        request.query_string.blank? &&
        turbo_frame_request_id.blank?
    end

    def guest_alphabetical_http_cacheable?
      guest_alphabetical_request? && (response.successful? || response.status == 304)
    end

    def guest_alphabetical_etag
      etag = guest_alphabetical_etag_parts
      etag << current_content_filter.fingerprint if current_content_filter.active?
      etag
    end

    def guest_alphabetical_etag_parts
      [
        'fiction_lists/alphabetical/v1',
        I18n.locale,
        cookies[:color_theme].presence || 'light',
        catalog_include_eighteen? ? '18' : 'no18',
        Fiction.maximum(:updated_at),
        Fiction.maximum(:last_chapter_at),
        Fiction.count
      ]
    end
  end
end
