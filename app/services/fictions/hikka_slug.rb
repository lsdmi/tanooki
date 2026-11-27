# frozen_string_literal: true

module Fictions
  # Reduces what an author pastes into the Hikka field to a bare novel slug. Accepts a slug or a link to a novel page
  # on hikka.io. Anything else is returned as typed (lowercased), so the model's format validation rejects it.
  class HikkaSlug
    MAX_LENGTH = 255
    FORMAT = /\A[a-z0-9-]+\z/
    NOVEL_URL = %r{\Ahttps?://(?:www\.)?hikka\.io/novel/([^/?#\s]+)/?(?:[?#]\S*)?\z}i

    def self.normalize(value)
      text = value.to_s.strip
      return if text.empty?

      match = text.match(NOVEL_URL)
      (match ? match[1] : text).downcase
    end
  end
end
