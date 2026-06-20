# frozen_string_literal: true

require 'test_helper'

class StudioTabFlashStreamTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'studio tab turbo stream clears stale layout flash after bookshelf create' do
    sign_in users(:user_one)
    fiction = fictions(:one)

    post bookshelves_url, params: {
      bookshelf: {
        title: 'Flash clear shelf',
        description: 'Test shelf',
        fiction_ids: [fiction.id]
      }
    }

    follow_redirect!

    assert_studio_tab_clears_flash_after_notice('Полицю дадано')
  end

  private

  def assert_studio_tab_clears_flash_after_notice(notice)
    assert_equal notice, flash[:notice]

    get tab_studio_path('teams'), as: :turbo_stream

    assert_response :success
    assert_select 'turbo-stream[target="application-notice"]', count: 1
    assert_not_includes response.body, notice
  end
end
