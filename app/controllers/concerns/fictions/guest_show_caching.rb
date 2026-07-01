# frozen_string_literal: true

module Fictions
  # Private browser Cache-Control for guest HTML fiction#show responses.
  module GuestShowCaching
    extend ActiveSupport::Concern

    included do
      after_action :set_guest_fiction_show_cache_headers
    end

    private

    def set_guest_fiction_show_cache_headers
      return unless action_name == 'show'
      return unless guest_fiction_show_http_cacheable?

      expires_in Fictions::ShowCacheHelper::GUEST_HTTP_EXPIRY, public: false, must_revalidate: true
    end

    def guest_fiction_show_http_cacheable?
      request.get? &&
        request.format.symbol == :html &&
        response.successful? &&
        current_user.nil?
    end
  end
end
