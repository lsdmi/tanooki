# frozen_string_literal: true

require 'test_helper'

module FictionReviews
  class EligibilityTest < ActiveSupport::TestCase
    LONG_TEXT = 'Дуже сподобався сюжет і переклад, герої живі, а світ продуманий до дрібниць. ' \
                'Чекаю продовження й дякую команді за роботу.'

    setup do
      @fiction = fictions(:two)
      @reader = users('user_101')
      @comment = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)
      FictionRating.create!(user: @reader, fiction: @fiction, rating: 4)
    end

    test 'a reader with a rating may review a fiction comment' do
      result = Eligibility.call(user: @reader, comment: @comment)

      assert result.ok
      assert_nil result.reason
      assert_equal @fiction, result.fiction
    end

    test 'a guest cannot review' do
      assert_equal :guest, Eligibility.call(user: nil, comment: @comment).reason
    end

    test 'a comment on a chapter is not a fiction comment' do
      comment = Comment.create!(user: @reader, commentable: chapters(:two), content: LONG_TEXT)

      assert_equal :not_fiction_comment, Eligibility.call(user: @reader, comment:).reason
    end

    test 'a soft-deleted fiction is unavailable' do
      @fiction.update!(deleted_at: Time.current)

      assert_equal :fiction_unavailable, Eligibility.call(user: @reader, comment: @comment).reason
    end

    test 'a team member may review their own fiction' do
      team_member = users(:user_two)
      ScanlatorUser.create!(scanlator: scanlators(:one), user: team_member)
      FictionRating.create!(user: team_member, fiction: @fiction, rating: 5)
      own = Comment.create!(user: team_member, commentable: @fiction, content: LONG_TEXT)

      assert Eligibility.call(user: team_member, comment: own).ok
    end

    test 'an admin may review their own fiction too' do
      admin = users(:user_one)
      FictionRating.create!(user: admin, fiction: @fiction, rating: 5)
      own = Comment.create!(user: admin, commentable: @fiction, content: LONG_TEXT)

      assert Eligibility.call(user: admin, comment: own).ok
    end

    test 'without a rating of the fiction there is no review' do
      FictionRating.where(user: @reader).delete_all

      assert_equal :no_rating, Eligibility.call(user: @reader, comment: @comment).reason
    end

    test 'a rating of another fiction does not count' do
      FictionRating.where(user: @reader).delete_all
      FictionRating.create!(user: @reader, fiction: fictions(:one), rating: 5)

      assert_equal :no_rating, Eligibility.call(user: @reader, comment: @comment).reason
    end

    test 'a reader who already has a review of the fiction is refused' do
      FictionReview.create!(comment: @comment, user: @reader, fiction: @fiction)
      other = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)

      assert_equal :already_has_review, Eligibility.call(user: @reader, comment: other).reason
    end
  end
end
