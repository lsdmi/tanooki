# frozen_string_literal: true

# One stack of a catalog item in a trainer's bag.
class TrainerItem < ApplicationRecord
  belongs_to :user

  validates :item_key, presence: true, uniqueness: { scope: :user_id }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
