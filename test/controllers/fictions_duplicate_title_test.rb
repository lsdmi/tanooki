# frozen_string_literal: true

require 'test_helper'

class FictionsDuplicateTitleTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
  end

  test 'new fiction form looks up titles while typing' do
    get new_fiction_url

    assert_response :success
    assert_select '[data-controller~="fiction-title-lookup"]'
    assert_select '[data-fiction-title-lookup-target="query"]', count: 2
  end

  test 'edit fiction form does not look up duplicates' do
    get edit_fiction_url(fictions(:one))

    assert_response :success
    assert_select '[data-controller~="fiction-title-lookup"]', count: 0
  end

  test 'lookup requires a user who can create fictions' do
    sign_out users(:user_one)
    get lookup_fictions_url

    assert_redirected_to new_user_session_path

    user = users(:user_two)
    user.scanlator_users.destroy_all
    sign_in user
    get lookup_fictions_url

    assert_redirected_to new_scanlator_path
  end

  test 'lookup lists matching fictions with a link to add chapters' do
    Fiction.stub(:search, ->(*_, **_) { [fictions(:one)] }) do
      get lookup_fictions_url, params: { q: 'Test Fiction' }
    end

    assert_response :success
    assert_select 'li', /Test Fiction/
    assert_select "a[href='#{new_chapter_path(fiction: 'one')}']", text: I18n.t('fictions.duplicates.add_chapters')
  end

  test 'create is blocked when the title matches an existing fiction' do
    assert_no_difference('Fiction.count') { post_fiction(title: 'Test Fiction!') }

    assert_response :unprocessable_content
    assert_select "input[name='fiction[different_work]'][type='checkbox']"
  end

  test 'create is blocked when the english title matches an existing fiction' do
    existing = fictions(:one)
    existing.english_title = 'Shared English'
    existing.save!(validate: false)

    assert_no_difference('Fiction.count') do
      post_fiction(title: 'Цілком інша назва', english_title: 'shared english!')
    end

    assert_response :unprocessable_content
    assert_select "a[href='#{new_chapter_path(fiction: existing.slug)}']"
  end

  test 'create is allowed when the different-work checkbox is ticked' do
    assert_difference('Fiction.count') { post_fiction(title: 'Test Fiction', different_work: '1') }

    assert_redirected_to fiction_path('test-fiction')
  end

  test 'create is not blocked by the alternative title alone' do
    assert_difference('Fiction.count') { post_fiction(title: 'Окремий новий твір', alternative_title: 'Test Fiction') }

    assert_response :redirect
  end

  test 'edit is not blocked by an existing title' do
    patch fiction_url(fictions(:two)), params: { fiction: { title: 'Test Fiction', scanlator_ids: [1] } }

    assert_redirected_to fiction_path(fictions(:two))
    assert_equal 'Test Fiction', fictions(:two).reload.title
  end

  private

  def post_fiction(**fiction_attrs)
    post fictions_url, params: {
      fiction: {
        title: 'New Fiction',
        author: 'New Author',
        description: 'a' * 50,
        cover: valid_cover_upload,
        scanlator_ids: [1]
      }.merge(fiction_attrs)
    }
  end
end
