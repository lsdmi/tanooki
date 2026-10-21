# frozen_string_literal: true

# Highest audience band an account still wants in discovery lists. Nil means no limit.
class UserContentFilter < ApplicationRecord
  # 16 hides 18+. 0 hides 16+ and 18+. 18 is not a cap: it hides nothing.
  ALLOWED_RATINGS = [0, 16].freeze

  belongs_to :user

  validates :max_content_rating, inclusion: { in: ALLOWED_RATINGS }, allow_nil: true
end
