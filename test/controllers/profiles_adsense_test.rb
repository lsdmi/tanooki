# frozen_string_literal: true

require 'test_helper'

class ProfilesAdsenseTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
    @sqid = Sqids.new.encode([@user.id])
  end

  test 'profile omits adsense slots outside development' do
    get profile_url(@sqid)

    assert_response :success
    assert_select '.profile-show__ad .reader-ad-slot', count: 0
  end

  test 'profile renders adsense preview under avatar in development' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get profile_url(@sqid)
    end

    assert_response :success
    assert_select ".profile-show__ad #adsense-slot-profile-#{@sqid}.reader-ad-slot--preview", count: 1
  end
end
