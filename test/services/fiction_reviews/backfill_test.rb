# frozen_string_literal: true

require 'test_helper'

module FictionReviews
  class BackfillTest < ActiveSupport::TestCase
    LONG_TEXT = 'Дуже сподобався сюжет і переклад, герої живі, а світ продуманий до дрібниць. ' \
                'Чекаю продовження й дякую команді за роботу.'

    setup do
      @fiction = fictions(:two)
      @reader = users('user_101')
      FictionRating.create!(user: @reader, fiction: @fiction, rating: 4)
      @comment = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)
    end

    test 'a dry run reports the outcome and writes nothing' do
      outcome = Backfill.call(comment_ids: [@comment.id]).first

      assert_equal [:marked, nil], [outcome.status, outcome.review_id]
    end

    test 'a dry run leaves no review and no count behind' do
      Backfill.call(comment_ids: [@comment.id])

      assert_equal [0, 0], [FictionReview.count, @fiction.reload.reviews_count]
    end

    test 'an applied run marks the comment as its author review' do
      outcome = Backfill.call(comment_ids: [@comment.id], apply: true).first

      assert_equal [:marked, @comment.reload.fiction_review.id], [outcome.status, outcome.review_id]
    end

    test 'an applied run counts the review on the fiction' do
      Backfill.call(comment_ids: [@comment.id], apply: true)

      assert_equal 1, @fiction.reload.reviews_count
    end

    test 'a dry run sees its own marks, so a second comment of the same reader is rejected' do
      other = Comment.create!(user: @reader, commentable: @fiction, content: "#{LONG_TEXT} Ще раз.")
      outcomes = Backfill.call(comment_ids: [@comment.id, other.id])

      assert_equal %i[marked rejected], outcomes.map(&:status)
      assert_equal :already_has_review, outcomes.last.reason
    end

    test 'a rejected comment carries the reason and does not stop the rest' do
      FictionRating.where(user: @reader).delete_all
      fine = Comment.create!(user: users('user_102'), commentable: @fiction, content: LONG_TEXT)
      FictionRating.create!(user: fine.user, fiction: @fiction, rating: 5)
      outcomes = Backfill.call(comment_ids: [@comment.id, fine.id], apply: true)

      assert_equal %i[rejected marked], outcomes.map(&:status)
      assert_equal :no_rating, outcomes.first.reason
    end

    test 'an unknown comment id is reported, not raised' do
      outcome = Backfill.call(comment_ids: [0]).first

      assert_equal :rejected, outcome.status
      assert_equal :comment_not_found, outcome.reason
    end

    test 'the same id twice is processed once' do
      outcomes = Backfill.call(comment_ids: [@comment.id, @comment.id], apply: true)

      assert_equal [:marked], outcomes.map(&:status)
    end

    test 'undo takes the mark off and keeps the comment' do
      review = Mark.call(comment: @comment, user: @reader).review
      outcome = Backfill.call(comment_ids: [@comment.id], apply: true, undo: true).first

      assert_equal [:unmarked, review.id], [outcome.status, outcome.review_id]
      assert_nil @comment.reload.fiction_review
    end

    test 'undo of a comment that is not marked is rejected' do
      outcome = Backfill.call(comment_ids: [@comment.id], apply: true, undo: true).first

      assert_equal :not_marked, outcome.reason
    end
  end
end
