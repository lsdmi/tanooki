# frozen_string_literal: true

class Tag < ApplicationRecord
  attr_accessor :publication_id

  has_many :publication_tags, dependent: :destroy
  has_many :publications, through: :publication_tags

  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }
end
