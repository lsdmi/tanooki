# frozen_string_literal: true

module Comments
  # Allowed polymorphic targets for user comments.
  class CommentableWhitelist
    ALLOWED_TYPES = %w[
      Chapter
      Contest
      Fiction
      Publication
      Tale
      YoutubeVideo
    ].freeze

    def self.allowed?(type)
      ALLOWED_TYPES.include?(type.to_s)
    end
  end
end
