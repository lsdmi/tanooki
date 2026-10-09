# frozen_string_literal: true

module Api
  # Remembers a create response for 24 hours so a retried request does not make a second chapter.
  # The key is scoped to the user. A blank key is not stored.
  class Idempotency
    TTL = 24.hours
    Replay = Data.define(:status, :body)

    def self.read(user, key)
      return if key.blank?

      cached = Rails.cache.read(cache_key(user, key))
      Replay.new(status: cached[:status], body: cached[:body]) if cached
    end

    def self.write(user, key, status:, body:)
      return if key.blank?

      Rails.cache.write(cache_key(user, key), { status:, body: }, expires_in: TTL)
    end

    def self.cache_key(user, key)
      digest = Digest::SHA256.hexdigest(key.to_s.first(255))
      "api/idempotency/#{user.id}/#{digest}"
    end
  end
end
