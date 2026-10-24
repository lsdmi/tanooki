# frozen_string_literal: true

require 'test_helper'

class ContentFilterExemptionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @user.content_filter.update!(max_content_rating: 0)
    sign_in @user
    @eighteen = fictions(:eighteen)
    @sixteen = fictions(:two)
  end

  test 'fiction show still opens an 18+ work' do
    get fiction_path(@eighteen)

    assert_response :success
    assert_select 'h1#fiction-title', text: @eighteen.title
  end

  test 'chapter show still opens a work above the cap' do
    fiction = fictions(:one)
    fiction.update!(content_rating: :eighteen)

    get chapter_path(chapters(:one))

    assert_response :success
    assert_select 'a[href=?]', fiction_path(fiction), text: fiction.title
  end

  test 'the library still lists a work above the cap' do
    get library_url

    assert_response :success
    assert_includes response.body, @sixteen.title
  end

  test 'the sitemap still lists an 18+ work' do
    get '/sitemap.xml'

    assert_response :success
    assert_includes response.body, "/fictions/#{@eighteen.slug}"
  end

  test 'the public api still lists an 18+ work' do
    get '/api/v1/fictions'

    assert_response :success
    assert_includes response.body, @eighteen.title
  end
end
