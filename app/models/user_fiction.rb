# frozen_string_literal: true

class UserFiction < ApplicationRecord
  belongs_to :fiction
  belongs_to :user

  validates :fiction_id, uniqueness: { scope: :user_id }
end
