# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :parent, class_name: 'Comment', inverse_of: :replies, optional: true
  belongs_to :user

  has_many :replies, foreign_key: :parent_id, dependent: :destroy, class_name: 'Comment'

  scope :parents, -> { where(parent_id: nil) }

  validates :content, presence: true, length: { maximum: 2200 }
end
