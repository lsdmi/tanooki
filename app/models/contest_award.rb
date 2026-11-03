# frozen_string_literal: true

# Prize assigned to a contest entry (place or nomination).
class ContestAward < ApplicationRecord
  include NormalizesWhitespace

  normalizes_squished :payout_note

  belongs_to :contest, inverse_of: :awards
  belongs_to :contest_prize, inverse_of: :awards
  belongs_to :contest_entry, inverse_of: :awards

  validates :awarded_at, presence: true
  validates :contest_prize_id, uniqueness: { scope: :contest_entry_id }

  def paid? = paid_at.present?
end
