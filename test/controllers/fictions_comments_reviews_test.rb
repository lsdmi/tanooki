# frozen_string_literal: true

require 'test_helper'

class FictionsCommentsReviewsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  LONG_TEXT = 'Дуже сподобався сюжет і переклад, герої живі, а світ продуманий до дрібниць. ' \
              'Чекаю продовження й дякую команді за роботу.'

  setup do
    sign_in users(:user_two)
    @fiction = fictions(:one)
    @reader = users('user_101')
    FictionRating.create!(user: @reader, fiction: @fiction, rating: 4)
    @review = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)
    FictionReview.create!(comment: @review, user: @reader, fiction: @fiction)
    @plain = Comment.create!(user: users(:user_two), commentable: @fiction, content: 'Звичайний коментар без оцінки')
    read_chapters(@reader, chapters(:one), chapters(:two))
  end

  test 'the reviews filter shows only the reviews' do
    get comments_fiction_url(@fiction, filter: 'reviews')

    assert_includes response.body, LONG_TEXT
    assert_not_includes response.body, @plain.content
  end

  test 'the default shows reviews and ordinary comments together' do
    get comments_fiction_url(@fiction)

    assert_includes response.body, LONG_TEXT
    assert_includes response.body, @plain.content
  end

  test 'a review carries the badge, the author’s stars and the chapters read' do
    get comments_fiction_url(@fiction)

    assert_select 'turbo-frame#comments article', text: /Відгук/
    assert_select 'article [role="img"][aria-label="Оцінка: 4 з 5"]'
    assert_select 'article', text: /Прочитано 2 розділи/
  end

  test 'a comment that is not a review has no badge' do
    get comments_fiction_url(@fiction)

    assert_select "turbo-frame#comment_#{@plain.id} [role='img']", count: 0
    assert_select "turbo-frame#comment_#{@plain.id}", text: /Відгук/, count: 0
  end

  test 'the filter is offered with the count when the fiction has reviews' do
    get comments_fiction_url(@fiction)

    assert_select %(nav a[href=?]), comments_fiction_path(@fiction, filter: 'reviews', order: :desc),
                  text: 'Відгуки (1)'
  end

  test 'the filter sits in a stable place, so a mark can redraw it even before the first review' do
    get comments_fiction_url(fictions(:two))

    assert_select '#fiction_review_filter', count: 1
    assert_select '#fiction_review_filter nav', count: 0
  end

  test 'a fiction without reviews has no filter' do
    get comments_fiction_url(fictions(:two))

    assert_select 'nav a', text: /Відгуки/, count: 0
  end

  test 'the order toggle keeps the reviews filter' do
    second = users(:user_two) # rated fiction one in the fixtures
    second_review = Comment.create!(user: second, commentable: @fiction, content: LONG_TEXT)
    FictionReview.create!(comment: second_review, user: second, fiction: @fiction)

    get comments_fiction_url(@fiction, filter: 'reviews')

    assert_select %(turbo-frame#fiction_comments a[href=?]),
                  comments_fiction_path(@fiction, order: :asc, filter: 'reviews'), text: /Новіші/
  end

  test 'a spoiler is collapsed behind a summary' do
    Comment.create!(user: users(:user_two), commentable: @fiction, content: 'Він помирає в кінці', spoiler: true)

    get comments_fiction_url(@fiction)

    assert_select 'details summary', text: 'Спойлер. Натисніть, щоб прочитати'
    assert_select 'details p', text: 'Він помирає в кінці'
    assert_no_match(/<details[^>]*open/, response.body)
  end

  test 'the comment form offers the spoiler checkbox' do
    get comments_fiction_url(@fiction)

    assert_select "turbo-frame#new_comment input[type='checkbox'][name='comment[spoiler]']", count: 1
  end

  private

  def read_chapters(user, *chapters)
    chapters.each do |chapter|
      ReadingChapterRead.create!(user:, fiction: chapter.fiction, chapter:, completed_at: Time.current,
                                 source: 'scroll')
    end
  end
end
