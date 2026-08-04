# frozen_string_literal: true

require 'test_helper'

class FictionsIndexAdsenseTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
  end

  test 'index omits adsense slots outside development' do
    get fictions_path

    assert_response :success
    assert_select '.adsense-collapse-safe', count: 0
  end

  test 'index renders adsense slot previews in development' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get fictions_path
    end

    assert_response :success
    assert_select '.adsense-collapse-safe #adsense-slot-fictions_index_top-top.reader-ad-slot--preview',
                  count: 1
    assert_select '.adsense-collapse-safe #adsense-slot-fictions_index_mid-mid.reader-ad-slot--preview',
                  count: 1
  end
end
