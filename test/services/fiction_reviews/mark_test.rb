# frozen_string_literal: true

require 'test_helper'

module FictionReviews
  class MarkTest < ActiveSupport::TestCase
    LONG_TEXT = 'Дуже сподобався сюжет і переклад, герої живі, а світ продуманий до дрібниць. ' \
                'Чекаю продовження й дякую команді за роботу.'

    setup do
      @fiction = fictions(:two)
      @reader = users('user_101')
      @comment = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)
      FictionRating.create!(user: @reader, fiction: @fiction, rating: 4)
    end

    test 'marking a comment creates the review and counts it' do
      result = Mark.call(comment: @comment, user: @reader)

      assert result.ok
      assert_equal @comment, result.review.comment
      assert_equal 1, @fiction.reload.reviews_count
    end

    test 'marking the same comment twice does not create a second review' do
      Mark.call(comment: @comment, user: @reader)
      result = Mark.call(comment: @comment, user: @reader)

      assert_not result.ok
      assert_equal :already_has_review, result.error
      assert_equal 1, FictionReview.where(user: @reader, fiction: @fiction).count
    end

    test 'a second review of the same fiction is refused without replacing the first' do
      first = Mark.call(comment: @comment, user: @reader).review
      other = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)
      result = Mark.call(comment: other, user: @reader)

      assert_equal :already_has_review, result.error
      assert_equal first, FictionReview.find_by(user: @reader, fiction: @fiction)
      assert_equal 1, @fiction.reload.reviews_count
    end

    test 'a reply cannot be a review' do
      reply = Comment.create!(user: @reader, commentable: @fiction, parent: @comment, content: LONG_TEXT)

      assert_equal :reply, Mark.call(comment: reply, user: @reader).error
    end

    test 'a comment on a chapter cannot be a review' do
      comment = Comment.create!(user: @reader, commentable: chapters(:two), content: LONG_TEXT)

      assert_equal :not_fiction_comment, Mark.call(comment:, user: @reader).error
    end

    test 'a short comment cannot be a review' do
      comment = Comment.create!(user: @reader, commentable: @fiction, content: 'коротко')

      assert_equal :too_short, Mark.call(comment:, user: @reader).error
      assert_equal 0, FictionReview.where(comment:).count
    end

    test 'a reader cannot mark someone else’s comment' do
      comment = Comment.create!(user: users(:user_one), commentable: @fiction, content: LONG_TEXT)

      assert_equal :not_owner, Mark.call(comment:, user: @reader).error
    end

    test 'a comment that is already a review is refused' do
      Mark.call(comment: @comment, user: @reader)

      assert_equal :already_has_review, Mark.call(comment: @comment, user: @reader).error
    end

    test 'a guest cannot mark anything' do
      assert_equal :guest, Mark.call(comment: @comment, user: nil).error
    end

    test 'a race on the reader index is reported as an existing review' do
      raise_unique(FictionReview, 'index_fiction_reviews_on_user_and_fiction') do
        assert_equal :already_has_review, Mark.call(comment: @comment, user: @reader).error
      end
    end

    test 'a race on the comment index is reported as an already marked comment' do
      raise_unique(FictionReview, 'index_fiction_reviews_on_comment_id') do
        assert_equal :already_marked, Mark.call(comment: @comment, user: @reader).error
      end
    end

    private

    def raise_unique(klass, index, &)
      error = ActiveRecord::RecordNotUnique.new("Duplicate entry for key 'fiction_reviews.#{index}'")
      klass.stub(:new, ->(*, **) { raise error }, &)
    end
  end
end
