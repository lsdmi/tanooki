# frozen_string_literal: true

require 'test_helper'

class ChaptersCalendarAdsenseTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    get calendar_fictions_path
  end

  test 'index omits adsense slots outside development' do
    assert_response :success
    assert_select '.adsense-collapse-safe', count: 0
  end

  test 'index renders adsense slot preview in development every fifth calendar item' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get calendar_fictions_path
    end

    assert_response :success

    max_items_in_day = Array(assigns(:fictions)).map { |day| day[:updates].size }.max.to_i
    if max_items_in_day >= 5
      assert_select '.adsense-collapse-safe #adsense-slot-fiction_calendar-day-0-item-5.reader-ad-slot--preview',
                    count: 1
    else
      assert_select '.adsense-collapse-safe', count: 0
    end
  end
end
