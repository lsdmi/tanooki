class Tale < ApplicationRecord
  validates :title, :description, presence: true
end
