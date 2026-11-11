# frozen_string_literal: true

require 'test_helper'

class ScanlatorsShowAdsenseTest < ActionDispatch::IntegrationTest
  setup do
    @scanlator = scanlators(:one)
  end

  test 'show omits adsense slots outside development' do
    @scanlator.update!(description: 'Team about text', notice: nil)

    get scanlator_url(@scanlator)

    assert_response :success
    assert_select '.scanlator-show__ad .reader-ad-slot', count: 0
  end

  test 'show inserts scanlator adsense in the works grid like storage mid-ad' do
    @scanlator.update!(description: 'Team about text', notice: nil)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get scanlator_url(@scanlator)
    end

    assert_response :success
    assert_select '.grid .scanlator-show__ad--full #adsense-slot-scanlator_show-' \
                  "#{@scanlator.id}-p1.reader-ad-slot--preview", count: 1
  end

  test 'show keeps mid-grid adsense when description and notice are blank' do
    @scanlator.update!(description: nil, notice: nil)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get scanlator_url(@scanlator)
    end

    assert_response :success
    assert_select '.grid .scanlator-show__ad--full #adsense-slot-scanlator_show-' \
                  "#{@scanlator.id}-p1.reader-ad-slot--preview", count: 1
  end

  test 'show places adsense after the empty state when the team has no works' do
    empty_team = scanlators(:two)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get scanlator_url(empty_team)
    end

    assert_response :success
    assert_select '.grid .scanlator-show__ad', count: 0
    assert_select '.scanlator-show__ad--full #adsense-slot-scanlator_show-' \
                  "#{empty_team.id}-empty.reader-ad-slot--preview", count: 1
  end

  test 'show inserts scanlator adsense in list view mid-list' do
    @scanlator.update!(description: 'Team about text', notice: nil)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get scanlator_url(@scanlator, view: 'list')
    end

    assert_response :success
    assert_select '.scanlator-show__ad--full #adsense-slot-scanlator_show-' \
                  "#{@scanlator.id}-p1.reader-ad-slot--preview", count: 1
  end
end
