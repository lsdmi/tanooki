# frozen_string_literal: true

module Chapters
  # Private browser Cache-Control for guest HTML chapters#show (same idea as fiction show).
  module GuestShowCaching
    extend ActiveSupport::Concern

    GUEST_HTTP_EXPIRY = 2.minutes

    included do
      after_action :set_guest_chapter_show_cache_headers
    end

    private

    def set_guest_chapter_show_cache_headers
      return unless action_name == 'show'
      return unless guest_chapter_show_http_cacheable?

      expires_in GUEST_HTTP_EXPIRY, public: false, must_revalidate: true
      response.headers['Vary'] = [response.headers['Vary'], 'Cookie'].compact_blank.join(', ')
    end

    def guest_chapter_show_http_cacheable?
      request.get? &&
        request.format.symbol == :html &&
        response.successful? &&
        current_user.nil?
    end
  end
end
