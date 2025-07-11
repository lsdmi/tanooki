# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true, counter_cache: true
  belongs_to :parent, class_name: 'Comment', inverse_of: :replies, optional: true
  belongs_to :user

  has_many :replies, foreign_key: :parent_id, dependent: :destroy, class_name: 'Comment'
  has_many :users, foreign_key: 'latest_read_comment_id', dependent: :nullify

  scope :parents, -> { where(parent_id: nil) }

  validates :content, presence: true, length: { maximum: 2200 }

  def username
    user.name
  end

  def parent_content
    parent&.content
  end
end
