# frozen_string_literal: true

require 'test_helper'

class FictionsCommentsThreadTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_two)
    @fiction = fictions(:one)
  end

  test 'newest first by default and oldest first with order=asc' do
    older = add_comment('Старший', created_at: 2.days.ago)
    newer = add_comment('Новіший', created_at: 1.hour.ago)

    get comments_fiction_url(@fiction)

    assert_operator response.body.index(newer.content), :<, response.body.index(older.content)
    assert_select 'turbo-frame#fiction_comments a[href=?]', comments_fiction_path(@fiction, order: :asc), text: /Новіші/

    get comments_fiction_url(@fiction, order: :asc)

    assert_operator response.body.index(older.content), :<, response.body.index(newer.content)
  end

  test 'pages top-level comments behind «Показати ще коментарі»' do
    add_page_and_one_more

    get comments_fiction_url(@fiction)

    assert_select 'turbo-frame#comments article', count: FictionShowPresenter::COMMENTS_PAGE_SIZE
    assert_select 'turbo-frame#comments_page_2 a[href=?]', comments_fiction_path(@fiction, order: :desc, page: 2),
                  text: 'Показати ще коментарі'
  end

  test 'next page renders only its own frame' do
    add_page_and_one_more

    get comments_fiction_url(@fiction, page: 2)

    assert_select 'turbo-frame#comments_page_2 article', count: 1
    assert_select 'turbo-frame#fiction_comments', count: 0
  end

  test 'replies are oldest first and those after the second wait behind «Показати ще N відповіді»' do
    parent = add_comment('Батьківський')
    replies = [3.hours.ago, 2.hours.ago, 1.hour.ago, 10.minutes.ago].each_with_index.map do |time, i|
      add_comment("Відповідь #{i}", created_at: time, parent:)
    end

    get comments_fiction_url(@fiction)

    assert_operator response.body.index(replies.first.content), :<, response.body.index(replies.last.content)
    assert_select "turbo-frame#replies-#{parent.id} > turbo-frame[hidden]", count: 2
    assert_select '[data-reveal-target="trigger"]', text: 'Показати ще 2 відповіді'
  end

  test 'members of the fiction teams are tagged «· Команда»' do
    team_comment = add_comment('Від команди', user: users(:user_one))
    reader_comment = add_comment('Від читача')

    get comments_fiction_url(@fiction)

    assert_select "turbo-frame#comment_#{team_comment.id} header p", text: /· Команда/
    assert_select "turbo-frame#comment_#{reader_comment.id} header p", text: /Команда/, count: 0
  end

  private

  def add_page_and_one_more
    (FictionShowPresenter::COMMENTS_PAGE_SIZE + 1).times { |i| add_comment("Коментар #{i}", created_at: i.minutes.ago) }
  end

  def add_comment(content, created_at: Time.current, parent: nil, user: users(:user_two))
    Comment.create!(content:, user:, commentable: @fiction, parent:, created_at:)
  end
end
