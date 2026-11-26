# frozen_string_literal: true

# User comment on a commentable resource (fiction, chapter, publication, etc.).
class Comment < ApplicationRecord
  include NormalizesWhitespace

  normalizes_stripped :content

  belongs_to :commentable, polymorphic: true, counter_cache: true
  belongs_to :parent, class_name: 'Comment', inverse_of: :replies, optional: true
  belongs_to :user

  has_many :replies, foreign_key: :parent_id, dependent: :destroy, class_name: 'Comment', inverse_of: :parent
  has_many :users, foreign_key: 'latest_read_comment_id', inverse_of: :latest_read_comment, dependent: :nullify
  has_one :fiction_review, dependent: :destroy

  scope :parents, -> { where(parent_id: nil) }

  validates :content, presence: true, length: { maximum: 2200 }
  validate :commentable_type_must_be_allowed
  validate :content_must_stay_review_length, on: :update

  def username
    user.name
  end

  def parent_content
    parent&.content
  end

  def chapter_comment?
    commentable_type == Chapter.name
  end

  private

  # Editing a review must not shrink it below the length it needed to become one.
  def content_must_stay_review_length
    return unless will_save_change_to_content? && fiction_review
    return if content.to_s.length >= FictionReview::MIN_LENGTH

    errors.add(:content, :review_too_short, count: FictionReview::MIN_LENGTH)
  end

  def commentable_type_must_be_allowed
    return if commentable_type.blank?
    return if Comments::CommentableWhitelist.allowed?(commentable_type)

    errors.add(:commentable_type, :inclusion)
  end
end
