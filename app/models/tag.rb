# frozen_string_literal: true

# Tag applied to publications.
class Tag < ApplicationRecord
  has_many :publication_tags, dependent: :destroy
  has_many :publications, through: :publication_tags

  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }
end
