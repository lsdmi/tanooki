# frozen_string_literal: true

# Star rating given by a user to a fiction.
class FictionRating < ApplicationRecord
  belongs_to :user
  belongs_to :fiction

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :fiction_id }
end
