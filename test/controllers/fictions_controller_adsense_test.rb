# frozen_string_literal: true

require 'test_helper'

class FictionsControllerAdsenseTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'production disables adsense on copyright-excluded fiction show' do
    @fiction.update!(slug: FictionsController::AD_EXCLUDED_SLUGS.first)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      get fiction_url(@fiction)

      assert_response :success
      assert_select 'body[data-load-adsense="false"]', count: 1
    end
  end

  test 'production disables adsense on copyright-excluded fiction edit' do
    @fiction.update!(slug: FictionsController::AD_EXCLUDED_SLUGS.first)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      get edit_fiction_url(@fiction)

      assert_response :success
      assert_select 'body[data-load-adsense="false"]', count: 1
    end
  end
end
