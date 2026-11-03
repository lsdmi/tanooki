# frozen_string_literal: true

# Public jury roster for a contest (scores are entered elsewhere).
class ContestJuror < ApplicationRecord
  include NormalizesWhitespace

  ROLES = %w[chair member].freeze

  normalizes_squished :public_bio

  belongs_to :contest, inverse_of: :jurors
  belongs_to :user

  enum :role, ROLES.index_by(&:to_sym), validate: true

  validates :user_id, uniqueness: { scope: :contest_id }
  validates :public_bio, length: { maximum: 255 }, allow_blank: true
end
