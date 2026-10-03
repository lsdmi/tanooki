# frozen_string_literal: true

require 'test_helper'

class FictionsControllerCommentsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'show defers comments in lazy turbo frame' do
    get fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_comments[loading="lazy"][src=?]', comments_fiction_path(@fiction)
    assert_select 'turbo-frame#comments', count: 0
    assert_select 'turbo-frame#new_comment', count: 0
  end

  test 'comments tab has a desktop sidebar with rating, rules and unique heading ids' do
    get fiction_url(@fiction)

    assert_select '#fiction-panel-comments aside #fiction-comments-rating-title'
    assert_select '#fiction-panel-comments aside #fiction-comment-rules-title', text: 'Правила коментарів'
    assert_select '#fiction-panel-comments aside a[href=?]', rules_path, text: 'Усі правила спільноти'
  end

  test 'comments frame renders the count, the composer and the list for a signed-in user' do
    get comments_fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_comments h2', text: "#{@fiction.comments_count} коментарів"
    assert_select 'turbo-frame#fiction_comments turbo-frame#new_comment textarea[placeholder=?]', 'Напишіть коментар…'
    assert_select 'turbo-frame#fiction_comments turbo-frame#comments'
  end

  test 'guest gets the login card instead of the composer and reply links to login' do
    sign_out :user

    get comments_fiction_url(fictions(:two))

    login = new_user_session_path(return_to: fiction_path(fictions(:two), anchor: 'comments'))

    assert_select 'turbo-frame#new_comment', count: 0
    assert_select 'turbo-frame#fiction_comments a[href=?][data-turbo-frame="_top"]', login, text: 'Увійти'
    assert_select 'turbo-frame#comments article a[href=?]', login, text: /Відповісти/
  end

  test 'no comments shows the empty state and keeps the list frame for the first comment' do
    sign_out :user

    get comments_fiction_url(@fiction)

    assert_select 'turbo-frame#fiction_comments p', text: 'Ще немає коментарів'
    assert_select 'turbo-frame#comments article', count: 0
    assert_select 'turbo-frame#comments'
  end
end
