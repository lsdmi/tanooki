# frozen_string_literal: true

require 'test_helper'

class StudioDeleteButtonsAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  STUDIO_DELETE_PARTIALS = %w[
    studio/tabs/_bookshelves.html.erb
    users/dashboard/_fictions.html.erb
    users/dashboard/_publications.html.erb
    scanlators/_team_card.html.erb
  ].freeze

  RAW_DELETE_PATTERN = /turbo[-_]method["']?\s*[:=]\s*:delete|method:\s*:delete/

  setup do
    sign_in users(:user_one)
  end

  test 'studio delete partials use sweet_alert_button not raw turbo delete links' do
    STUDIO_DELETE_PARTIALS.each do |partial|
      content = Rails.root.join('app/views', partial).read

      assert_no_match RAW_DELETE_PATTERN, content, "raw delete link in #{partial}"
      assert_includes content, 'sweet_alert_button', "expected sweet_alert_button in #{partial}"
    end
  end

  test 'studio tabs with list deletes render sweet-alert stimulus wiring' do
    %w[blogs writings teams bookshelves].each do |tab|
      get studio_index_path(tab: tab)

      assert_response :success
      assert_select 'button.sweet-alert-button[data-controller="sweet-alert"]', minimum: 1
      assert_select 'button.sweet-alert-button[data-action*="sweet-alert#confirm"]', minimum: 1
    end
  end

  test 'author readings chapter list uses sweet-alert delete buttons' do
    get reading_url(fictions(:one))

    assert_response :success
    assert_select 'button.sweet-alert-button[data-controller="sweet-alert"]', minimum: 1
    assert_no_match RAW_DELETE_PATTERN, response.body
  end
end
