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
    assert_select 'section.index-banners', count: 0
  end

  test 'index renders one banner row with two columns in development' do
    visit_index_in_development

    assert_select 'section.index-banners[aria-label="Реклама"]', count: 1
    assert_select '.index-banners__slot', count: 2
  end

  test 'index keeps the top and mid units as the left and right columns' do
    visit_index_in_development

    assert_select '.index-banners__slot:nth-child(1) #adsense-slot-fictions_index_top-top', count: 1
    assert_select '.index-banners__slot:nth-child(1) #adsense-slot-fictions_index_mid-mid', count: 0
  end

  test 'index no longer renders the standalone collapse-safe wrappers' do
    visit_index_in_development

    assert_select '.adsense-collapse-safe', count: 0
  end

  private

  def visit_index_in_development
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get fictions_path
    end

    assert_response :success
  end
end
