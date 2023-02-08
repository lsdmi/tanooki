class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :parent, optional: true, class_name: 'Comment', inverse_of: :comments
  belongs_to :user

  has_many :comments, foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent

  scope :parents, -> { where(parent_id: nil) }

  validates :content, presence: true, length: { maximum: 2200 }
end
