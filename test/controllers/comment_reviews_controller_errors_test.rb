# frozen_string_literal: true

require 'test_helper'

class CommentReviewsControllerErrorsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  LONG_TEXT = 'Дуже сподобався сюжет і переклад, герої живі, а світ продуманий до дрібниць. ' \
              'Чекаю продовження й дякую команді за роботу.'

  setup do
    ActionController::Base.cache_store.clear
    @fiction = fictions(:two)
    @reader = users('user_101')
    @comment = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)
    FictionRating.create!(user: @reader, fiction: @fiction, rating: 4)
    sign_in @reader
  end

  test 'a reply gets 422' do
    reply = Comment.create!(user: @reader, commentable: @fiction, parent: @comment, content: LONG_TEXT)

    assert_no_difference('FictionReview.count') { post comment_review_path(reply, format: :turbo_stream) }

    assert_response :unprocessable_content
    assert_includes response.body, 'Відповідь не може бути відгуком'
  end

  test 'a comment on a chapter gets 422' do
    chapter_comment = Comment.create!(user: @reader, commentable: chapters(:two), content: LONG_TEXT)

    assert_no_difference('FictionReview.count') { post comment_review_path(chapter_comment, format: :turbo_stream) }

    assert_response :unprocessable_content
    assert_includes response.body, 'Відгуком може бути лише коментар до твору'
  end

  test 'a reader without a rating gets 422' do
    FictionRating.where(user: @reader, fiction: @fiction).delete_all

    assert_no_difference('FictionReview.count') { post comment_review_path(@comment, format: :turbo_stream) }

    assert_response :unprocessable_content
    assert_includes response.body, 'Спочатку поставте оцінку цьому твору'
  end

  test 'a second review of the same fiction gets 422' do
    post comment_review_path(@comment, format: :turbo_stream)
    other = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)

    assert_no_difference('FictionReview.count') { post comment_review_path(other, format: :turbo_stream) }

    assert_response :unprocessable_content
    assert_includes response.body, 'Ви вже лишали відгук на цей твір'
  end

  test 'a short comment gets 422' do
    short = Comment.create!(user: @reader, commentable: @fiction, content: 'Коротко, але сподобалось')

    assert_no_difference('FictionReview.count') { post comment_review_path(short, format: :turbo_stream) }

    assert_response :unprocessable_content
    assert_includes response.body, 'Відгук має містити щонайменше 100 символів'
  end

  test 'taking off a comment that is not a review gets 422' do
    assert_no_difference('FictionReview.count') { delete comment_review_path(@comment, format: :turbo_stream) }

    assert_response :unprocessable_content
    assert_includes response.body, 'Цей коментар не позначено відгуком'
  end

  test 'marks and unmarks are limited to 10 per minute per user' do
    10.times { delete comment_review_path(@comment, format: :turbo_stream) }

    delete comment_review_path(@comment, format: :turbo_stream)

    assert_response :too_many_requests
    assert_includes response.body, 'Забагато змін за хвилину'
  end
end
