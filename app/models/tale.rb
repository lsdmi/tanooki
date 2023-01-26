class Tale < ApplicationRecord
  has_rich_text :description

  validates :title, :description, presence: true
end
