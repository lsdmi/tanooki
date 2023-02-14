# frozen_string_literal: true

class Content < ApplicationRecord
  self.abstract_class = true

  searchkick

  has_one_attached :cover
  has_rich_text :description

  has_many :comments, as: :commentable

  validates :title, :description, presence: true

  def search_data
    {
      title:,
      description: description.to_plain_text
    }
  end
end
