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

  test 'show renders full-width adsense when any sidebar card is present' do
    @scanlator.update!(description: 'Team about text', notice: nil)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get scanlator_url(@scanlator)
    end

    assert_response :success
    assert_select '.scanlator-show__ad--full #adsense-slot-scanlator_show-' \
                  "#{@scanlator.id}.reader-ad-slot--preview", count: 1
    assert_select '.scanlator-show__ad--sidebar', count: 0
  end

  test 'show renders full-width adsense when both sidebar cards are present' do
    @scanlator.update!(description: 'Team about text', notice: 'Team notice text')

    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get scanlator_url(@scanlator)
    end

    assert_response :success
    assert_select '.scanlator-show__ad--full #adsense-slot-scanlator_show-' \
                  "#{@scanlator.id}.reader-ad-slot--preview", count: 1
    assert_select '.scanlator-show__ad--sidebar', count: 0
  end

  test 'show renders left-column adsense when description and notice are blank' do
    @scanlator.update!(description: nil, notice: nil)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get scanlator_url(@scanlator)
    end

    assert_response :success
    assert_select '.scanlator-show__ad--sidebar #adsense-slot-scanlator_show-' \
                  "#{@scanlator.id}.reader-ad-slot--preview", count: 1
    assert_select '.scanlator-show__ad--full', count: 0
  end
end
