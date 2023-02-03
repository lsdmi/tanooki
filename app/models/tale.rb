class Tale < ApplicationRecord
  has_one_attached :cover
  has_rich_text :description

  validates :title, :description, presence: true

  scope :highlight, -> { where(highlight: true).last }
end
