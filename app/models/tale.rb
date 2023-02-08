class Tale < ApplicationRecord
  has_one_attached :cover
  has_rich_text :description

  has_many :comments, as: :commentable

  validates :title, :description, presence: true

  scope :highlight, -> { where(highlight: true).last }
end
