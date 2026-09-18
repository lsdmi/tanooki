# frozen_string_literal: true

module Fictions
  # Private browser Cache-Control / validators for guest HTML fictions#index.
  module GuestIndexCaching
    private

    def serve_fresh_guest_fiction_index?
      return false unless guest_fiction_index_request?

      apply_guest_fiction_index_http_cache
      return false unless request.fresh?(response)

      head :not_modified
      true
    end

    def set_guest_fiction_index_cache_headers
      return unless guest_fiction_index_http_cacheable?

      apply_guest_fiction_index_http_cache
    end

    def apply_guest_fiction_index_http_cache
      response.etag = guest_fiction_index_etag
      expires_in Fictions::ShowCacheHelper::GUEST_HTTP_EXPIRY, public: false, must_revalidate: true
    end

    def instrument_guest_fiction_index
      cache_before = Fictions::IndexVariablesManager.cache_hit_snapshot
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      Rails.logger.info(
        '[fictions.index] ' \
        "duration_ms=#{duration_ms} status=#{response.status} " \
        "cache=#{Fictions::IndexVariablesManager.format_cache_hit_snapshot(cache_before)}"
      )
    end

    def guest_fiction_index_request?
      request.get? &&
        request.format.symbol == :html &&
        current_user.nil? &&
        request.query_string.blank?
    end

    def guest_fiction_index_http_cacheable?
      guest_fiction_index_request? && (response.successful? || response.status == 304)
    end

    def guest_fiction_index_etag
      [
        'fictions/index/v1',
        I18n.locale,
        cookies[:color_theme].presence || 'light',
        Fictions::IndexVariablesManager.http_cache_fingerprint
      ]
    end
  end
end
