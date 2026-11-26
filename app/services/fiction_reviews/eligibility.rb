# frozen_string_literal: true

module FictionReviews
  # Business rules for marking a comment as its author's review: a rating of the fiction, the fiction still exists,
  # one review per reader. Team members and admins may review their own fiction like anyone else.
  # The structure of the comment (top level, its own, on the fiction, long enough) belongs to FictionReview;
  # Mark maps those model errors to the same reasons.
  class Eligibility
    Result = Data.define(:ok, :reason, :fiction)

    def self.call(...) = new(...).call

    def initialize(user:, comment:)
      @user = user
      @comment = comment
    end

    def call
      reason = failure_reason
      return Result.new(ok: false, reason:, fiction: nil) if reason

      Result.new(ok: true, reason: nil, fiction:)
    end

    private

    def failure_reason
      return :guest unless @user
      return :not_fiction_comment if fiction.nil?
      return :fiction_unavailable if fiction.deleted?
      return :no_rating unless FictionRating.exists?(user: @user, fiction:)
      return :already_has_review if FictionReview.exists?(user: @user, fiction:)

      nil
    end

    # The fiction is looked up with deleted ones included: a soft-deleted fiction must report :fiction_unavailable,
    # not look like a missing comment target.
    def fiction
      return @fiction if defined?(@fiction)

      @fiction = if @comment.commentable_type == Fiction.name
                   Fiction.with_deleted.find_by(id: @comment.commentable_id)
                 end
    end
  end
end
