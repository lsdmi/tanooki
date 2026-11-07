# frozen_string_literal: true

require 'test_helper'

class ContestsAdsenseTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'results show renders contest adsense banner preview in development' do
    sign_in users(:user_one)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get contest_path(contests(:results))

      assert_response :success
      assert_select '#results #adsense-slot-contests_show_top-top.reader-ad-slot--preview', count: 1
      assert_select '#results #adsense-slot-contests_show_mid-mid.reader-ad-slot--preview', count: 1
    end
  end
end
