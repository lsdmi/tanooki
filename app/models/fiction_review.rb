# frozen_string_literal: true

# Marks one top-level comment on a fiction as its author's review. The text lives in the comment; this row only
# points at it, so (user, fiction) is unique in the database and the fiction keeps a `reviews_count`.
class FictionReview < ApplicationRecord
  MIN_LENGTH = 100

  belongs_to :comment
  belongs_to :user
  belongs_to :fiction, counter_cache: :reviews_count

  validates :user_id, uniqueness: { scope: :fiction_id }
  validates :comment_id, uniqueness: true
  validate :comment_is_a_fiction_comment_of_the_author
  validate :comment_is_long_enough

  after_commit :invalidate_scanlator_stats, on: %i[create destroy]

  private

  def comment_is_a_fiction_comment_of_the_author
    return if comment.nil?

    errors.add(:comment, :not_top_level) if comment.parent_id.present?
    errors.add(:comment, :not_on_fiction) unless on_this_fiction?
    errors.add(:comment, :not_by_author) unless comment.user_id == user_id
  end

  def comment_is_long_enough
    return if comment.nil? || comment.content.to_s.length >= MIN_LENGTH

    errors.add(:comment, :too_short, count: MIN_LENGTH)
  end

  def on_this_fiction?
    comment.commentable_type == Fiction.name && comment.commentable_id == fiction_id
  end

  def invalidate_scanlator_stats
    Scanlators::StatsCacheInvalidation.for_fiction(fiction)
  end
end
