# frozen_string_literal: true

module FictionReviews
  # Marks a reviewed list of old comments as their authors' reviews (bin/prod/mark-reviews), or takes those marks
  # off again. Each comment goes through Mark, so the rules are the same as for a reader pressing «Позначити».
  # Without `apply` the whole run happens inside a transaction that is rolled back, so the report is what a real
  # run would do and nothing is written.
  class Backfill
    Outcome = Data.define(:comment_id, :status, :reason, :review_id)

    def self.call(...) = new(...).call

    def initialize(comment_ids:, apply: false, undo: false)
      @comment_ids = comment_ids.uniq
      @apply = apply
      @undo = undo
    end

    def call
      return run if @apply

      outcomes = nil
      ActiveRecord::Base.transaction(requires_new: true) do
        outcomes = run
        raise ActiveRecord::Rollback
      end
      outcomes.map { |outcome| outcome.with(review_id: nil) }
    end

    private

    def run = @comment_ids.map { |id| process(id) }

    def process(id)
      comment = Comment.find_by(id:)
      return Outcome.new(comment_id: id, status: :rejected, reason: :comment_not_found, review_id: nil) unless comment

      @undo ? unmark(comment) : mark(comment)
    end

    # The author does it: that is the same call the «Позначити» button makes.
    def mark(comment)
      result = Mark.call(comment:, user: comment.user)
      return rejected(comment, result.error) unless result.ok

      Outcome.new(comment_id: comment.id, status: :marked, reason: nil, review_id: result.review.id)
    end

    def unmark(comment)
      review_id = comment.fiction_review&.id
      result = Unmark.call(comment:, user: comment.user)
      return rejected(comment, result.error) unless result.ok

      Outcome.new(comment_id: comment.id, status: :unmarked, reason: nil, review_id:)
    end

    def rejected(comment, reason)
      Outcome.new(comment_id: comment.id, status: :rejected, reason:, review_id: nil)
    end
  end
end
