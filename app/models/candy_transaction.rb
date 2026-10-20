# frozen_string_literal: true

# Ledger row for every candy award or spend.
class CandyTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :source, polymorphic: true, optional: true

  validates :amount, :reason, presence: true
end
