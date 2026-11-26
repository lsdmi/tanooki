# frozen_string_literal: true

require 'test_helper'

module FictionReviews
  class UnmarkTest < ActiveSupport::TestCase
    LONG_TEXT = 'Дуже сподобався сюжет і переклад, герої живі, а світ продуманий до дрібниць. ' \
                'Чекаю продовження й дякую команді за роботу.'

    setup do
      @fiction = fictions(:two)
      @reader = users('user_101')
      @comment = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)
      FictionRating.create!(user: @reader, fiction: @fiction, rating: 4)
      Mark.call(comment: @comment, user: @reader)
    end

    test 'the author takes the mark off and the comment stays' do
      assert Unmark.call(comment: @comment, user: @reader).ok
      assert_empty FictionReview.where(comment: @comment)
      assert_equal LONG_TEXT, @comment.reload.content
    end

    test 'taking the mark off updates the fiction count' do
      Unmark.call(comment: @comment, user: @reader)

      assert_equal 0, @fiction.reload.reviews_count
    end

    test 'an admin can take the mark off someone else’s review' do
      result = Unmark.call(comment: @comment, user: users(:user_one))

      assert result.ok
      assert_equal 0, FictionReview.where(comment: @comment).count
    end

    test 'another reader cannot take the mark off' do
      result = Unmark.call(comment: @comment, user: users(:user_two))

      assert_not result.ok
      assert_equal :not_allowed, result.error
      assert_equal 1, FictionReview.where(comment: @comment).count
    end

    test 'a comment without a review has nothing to take off' do
      plain = Comment.create!(user: @reader, commentable: @fiction, content: 'звичайний коментар')

      assert_equal :not_marked, Unmark.call(comment: plain, user: @reader).error
    end

    test 'a guest cannot take the mark off' do
      assert_equal :guest, Unmark.call(comment: @comment, user: nil).error
    end
  end
end
