# frozen_string_literal: true

require 'test_helper'

module Users
  class ContentFiltersControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'an account saves a rating cap and one package' do
      user = users(:user_one)
      sign_in user

      patch content_filter_path,
            params: { max_content_rating: '0', package_keys: ['shelves'] },
            as: :turbo_stream

      assert_response :success
      assert_turbo_stream_flash_notice(I18n.t('content_filters.saved'))
      stored = [user.reload.content_filter.max_content_rating, user.hidden_packages.pluck(:package_key)]

      assert_equal [0, ['shelves']], stored
    end

    test 'profile portraits write the hidden avatar field' do
      sign_in users(:user_two)

      get studio_index_path(tab: 'profile')

      assert_select 'img[data-controller=?][data-avatar-id]', 'image-click'
      assert_select 'input#user_avatar_id[type=hidden]'
    end

    test 'the profile tab shows the saved choice' do
      user = users(:user_two)
      sign_in user

      get studio_index_path(tab: 'profile')

      assert_response :success
      assert_match(/id="content_filter_rating_all"[^>]*checked/, response.body)
      assert_select 'input#content_filter_package_shelves[checked]'
    end

    test 'reset opens the catalogue again' do
      user = users(:user_two)
      sign_in user

      patch content_filter_path, params: { max_content_rating: '' }, as: :turbo_stream

      assert_response :success
      assert_empty user.reload.hidden_packages.to_a
      assert_match(/id="content_filter_rating_all"[^>]*checked/, response.body)
    end

    test 'a rejected save keeps the stored filter' do
      user = users(:user_one)
      sign_in user

      patch content_filter_path,
            params: { max_content_rating: '18', package_keys: ['shelves'] },
            as: :turbo_stream

      assert_response :unprocessable_content
      assert_includes response.body, I18n.t('content_filters.errors.rating')
      assert_equal 16, user.reload.content_filter.max_content_rating
    end

    test 'a guest cookie hides 18+ and ignores packages' do
      assert_no_difference('UserHiddenPackage.count') do
        patch content_filter_path,
              params: { max_content_rating: '16', package_keys: ['shelves'] },
              as: :turbo_stream
      end

      assert_response :success
      assert_guest_cookie_kept
    end

    test 'the alphabetical page keeps the guest toggle checked' do
      patch content_filter_path, params: { max_content_rating: '16' }
      get alphabetical_fictions_path

      assert_response :success
      assert_match(/id="guest-content-filter-mobile_toggle"[^>]*checked/, response.body)
      assert_match(/id="guest-content-filter-desktop_toggle"[^>]*checked/, response.body)
    end

    test 'a guest can clear the cookie' do
      patch content_filter_path, params: { max_content_rating: '16' }, as: :turbo_stream
      patch content_filter_path, params: { max_content_rating: '' }, as: :turbo_stream

      assert_response :success
      assert_match(/max-age=0/i, response.get_header('Set-Cookie'))
      assert_no_match(/id="guest-content-filter-mobile_toggle"[^>]*checked/, response.body)
    end

    test 'an account cannot save an unknown package' do
      user = users(:user_one_one_zero)
      sign_in user

      patch content_filter_path, params: { max_content_rating: '', package_keys: ['not-a-package'] }, as: :turbo_stream

      assert_response :unprocessable_content
      assert_includes response.body, I18n.t('content_filters.errors.package')
      assert_nil user.reload.content_filter
    end

    test 'an account cannot turn off a second package' do
      user = users(:user_one_one_zero)
      sign_in user

      patch content_filter_path,
            params: { max_content_rating: '16', package_keys: %w[shelves another_world] },
            as: :turbo_stream

      assert_response :unprocessable_content
      assert_includes response.body, I18n.t('content_filters.errors.cap')
      assert_nil user.reload.content_filter
    end

    private

    def assert_guest_cookie_kept
      header = response.get_header('Set-Cookie')

      assert_match(/httponly/i, header)
      assert_match(/samesite=lax/i, header)
      assert_operator Time.httpdate(header[/expires=([^;]+)/i, 1]), :>, 300.days.from_now
    end
  end
end
