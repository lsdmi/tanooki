# frozen_string_literal: true

require 'test_helper'

class FictionListsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get alphabetical' do
    get alphabetical_fictions_url

    assert_response :success
    assert_template :alphabetical
  end

  test 'should get alphabetical with only_finished param' do
    get alphabetical_fictions_url, params: { only_finished: 'on' }

    assert_response :success
    assert_template :alphabetical
  end

  test 'should respond with turbo stream format' do
    get alphabetical_fictions_url(format: :turbo_stream)

    assert_response :success
    assert_match(/turbo-stream/, @response.media_type)
  end

  test 'alphabetical default omits eighteen and keeps sixteen' do
    get alphabetical_fictions_url

    assert_response :success
    assert_select 'a[href=?]', fiction_path(fictions(:two))
    assert_select 'a[href=?]', fiction_path(fictions(:eighteen)), count: 0
  end

  test 'alphabetical include_eighteen shows eighteen works' do
    get alphabetical_fictions_url, params: { include_eighteen: '1' }

    assert_response :success
    assert_select 'a[href=?]', fiction_path(fictions(:eighteen))
    assert_select 'input[name=include_eighteen][checked]'
  end

  test 'alphabetical still accepts legacy adult_content param' do
    get alphabetical_fictions_url, params: { adult_content: '1' }

    assert_response :success
    assert_select 'a[href=?]', fiction_path(fictions(:eighteen))
    assert_select 'input[name=include_eighteen][checked]'
  end

  test 'alphabetical filter label asks to show eighteen' do
    get alphabetical_fictions_url

    assert_select 'label', text: /Показувати 18\+/
  end

  test 'filter apply remembers include_eighteen in the session' do
    get alphabetical_fictions_url, params: { filters_applied: '1', include_eighteen: '1' }

    assert session[:catalog_include_eighteen]
    assert_select 'a[href=?]', fiction_path(fictions(:eighteen))
  end

  test 'bare alphabetical visit reuses the session preference' do
    get alphabetical_fictions_url, params: { filters_applied: '1', include_eighteen: '1' }
    get alphabetical_fictions_url

    assert_select 'a[href=?]', fiction_path(fictions(:eighteen))
    assert_select 'input[name=include_eighteen][checked]'
  end

  test 'filter apply can clear the remembered preference' do
    get alphabetical_fictions_url, params: { filters_applied: '1', include_eighteen: '1' }
    get alphabetical_fictions_url, params: { filters_applied: '1' }

    assert_nil session[:catalog_include_eighteen]
    assert_select 'a[href=?]', fiction_path(fictions(:eighteen)), count: 0
  end

  test 'signed-in readers also use the session preference' do
    sign_in users(:user_two)

    get alphabetical_fictions_url, params: { filters_applied: '1', include_eighteen: '1' }

    assert session[:catalog_include_eighteen]

    get alphabetical_fictions_url

    assert_select 'a[href=?]', fiction_path(fictions(:eighteen))
  end
end
