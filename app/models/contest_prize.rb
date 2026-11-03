# frozen_string_literal: true

# Place, nomination, or participation prize defined on a contest.
class ContestPrize < ApplicationRecord
  include NormalizesWhitespace

  KINDS = %w[place nomination participation continuation].freeze

  normalizes_squished :title, :perks

  belongs_to :contest, inverse_of: :prizes
  belongs_to :avatar, optional: true
  has_many :awards, class_name: 'ContestAward', dependent: :restrict_with_exception, inverse_of: :contest_prize

  enum :kind, KINDS.index_by(&:to_sym), validate: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :cash_uah, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :place, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :unlock_at_uah, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
