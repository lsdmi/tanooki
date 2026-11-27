# frozen_string_literal: true

module Fictions
  # The cached list Hikka reads from GET /api/v1/fictions. One place owns the key, so nobody deletes it by hand.
  class HikkaFeed
    KEY = 'fictions_hikka'
    TTL = 1.hour

    def self.fetch
      Rails.cache.fetch(KEY, expires_in: TTL) { Fiction.with_attached_cover.map(&:as_hikka_json) }
    end

    def self.bust
      Rails.cache.delete(KEY)
    end
  end
end
