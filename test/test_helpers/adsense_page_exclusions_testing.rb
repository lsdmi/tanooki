# frozen_string_literal: true

module AdsensePageExclusionsTesting
  def in_production(&)
    Rails.stub(:env, ActiveSupport::StringInquirer.new('production'), &)
  end

  def assert_auto_ads_disabled_manual_enabled
    yield

    assert_response :success
    assert_select 'body[data-load-adsense="true"][data-auto-ads="false"]', count: 1
  end

  def assert_adsense_fully_enabled
    yield

    assert_response :success
    assert_select 'body[data-load-adsense="true"][data-auto-ads="true"]', count: 1
  end

  def assert_adsense_fully_disabled
    yield

    assert_response :success
    assert_select 'body[data-load-adsense="false"][data-auto-ads="false"]', count: 1
  end
end
