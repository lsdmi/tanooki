# frozen_string_literal: true

require 'test_helper'

class FictionReviewTest < ActiveSupport::TestCase
  LONG_TEXT = 'Дуже сподобався сюжет і переклад, герої живі, а світ продуманий до дрібниць. ' \
              'Раджу всім, хто любить повільні історії з характером.'

  setup do
    @fiction = fictions(:two)
    @user = users(:user_two)
    @comment = Comment.create!(user: @user, commentable: @fiction, content: LONG_TEXT)
  end

  test 'a comment on a fiction becomes its author review' do
    review = FictionReview.new(comment: @comment, user: @user, fiction: @fiction)

    assert_predicate review, :valid?
  end

  test 'a reader has one review per fiction' do
    FictionReview.create!(comment: @comment, user: @user, fiction: @fiction)
    other = Comment.create!(user: @user, commentable: @fiction, content: LONG_TEXT)
    duplicate = FictionReview.new(comment: other, user: @user, fiction: @fiction)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], 'Ви вже лишали відгук на цей твір'
  end

  test 'the database refuses a second review for the same reader and fiction' do
    FictionReview.create!(comment: @comment, user: @user, fiction: @fiction)
    other = Comment.create!(user: @user, commentable: @fiction, content: LONG_TEXT)
    duplicate = FictionReview.new(comment: other, user: @user, fiction: @fiction)

    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test 'one comment is one review' do
    FictionReview.create!(comment: @comment, user: @user, fiction: @fiction)
    duplicate = FictionReview.new(comment: @comment, user: users(:user_one), fiction: @fiction)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:comment_id], 'цей коментар уже позначено відгуком'
  end

  test 'a reply cannot be a review' do
    reply = Comment.create!(user: @user, commentable: @fiction, parent: @comment, content: LONG_TEXT)
    review = FictionReview.new(comment: reply, user: @user, fiction: @fiction)

    assert_not review.valid?
    assert_includes review.errors[:comment], 'відповідь не може бути відгуком'
  end

  test 'a chapter comment cannot be a review' do
    chapter_comment = Comment.create!(user: @user, commentable: chapters(:two), content: LONG_TEXT)
    review = FictionReview.new(comment: chapter_comment, user: @user, fiction: @fiction)

    assert_not review.valid?
    assert_includes review.errors[:comment], 'відгуком може бути лише коментар до твору'
  end

  test 'a comment on another fiction cannot be a review of this one' do
    review = FictionReview.new(comment: @comment, user: @user, fiction: fictions(:one))

    assert_not review.valid?
    assert_includes review.errors[:comment], 'відгуком може бути лише коментар до твору'
  end

  test 'only the author of a comment can mark it as a review' do
    review = FictionReview.new(comment: @comment, user: users(:user_one), fiction: @fiction)

    assert_not review.valid?
    assert_includes review.errors[:comment], 'позначити відгуком можна лише власний коментар'
  end

  test 'a short comment cannot be a review' do
    short = Comment.create!(user: @user, commentable: @fiction, content: 'a' * (FictionReview::MIN_LENGTH - 1))
    review = FictionReview.new(comment: short, user: @user, fiction: @fiction)

    assert_not review.valid?
    assert_includes review.errors[:comment], "має містити щонайменше #{FictionReview::MIN_LENGTH} символів"
  end

  test 'the fiction counts its reviews' do
    review = FictionReview.create!(comment: @comment, user: @user, fiction: @fiction)

    assert_equal 1, @fiction.reload.reviews_count

    review.destroy!

    assert_equal 0, @fiction.reload.reviews_count
  end

  test 'removing the mark keeps the comment' do
    review = FictionReview.create!(comment: @comment, user: @user, fiction: @fiction)

    review.destroy!

    assert Comment.exists?(@comment.id)
  end

  test 'deleting the comment removes the review and the count' do
    FictionReview.create!(comment: @comment, user: @user, fiction: @fiction)

    @comment.destroy!

    assert_equal 0, FictionReview.where(fiction: @fiction).count
    assert_equal 0, @fiction.reload.reviews_count
  end

  test 'deleting the reader removes the review' do
    FictionReview.create!(comment: @comment, user: @user, fiction: @fiction)

    @user.destroy!

    assert_equal 0, FictionReview.where(fiction: @fiction).count
  end

  test 'the review drops cached scanlator stats' do
    invalidated = []
    stub = ->(fiction) { invalidated << fiction.id }

    Scanlators::StatsCacheInvalidation.stub(:for_fiction, stub) do
      review = FictionReview.create!(comment: @comment, user: @user, fiction: @fiction)
      review.destroy!
    end

    assert_equal [@fiction.id, @fiction.id], invalidated
  end
end
