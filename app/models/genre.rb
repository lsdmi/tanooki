# frozen_string_literal: true

class Genre < ApplicationRecord
  has_many :fiction_genres, dependent: :destroy
  has_many :fictions, through: :fiction_genres

  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }
end
