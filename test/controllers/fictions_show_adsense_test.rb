# frozen_string_literal: true

require 'test_helper'

class FictionsShowAdsenseTest < ActionDispatch::IntegrationTest
  setup do
    @fiction = fictions(:one)
    Rails.cache.delete("fiction_#{@fiction.id}")
  end

  test 'show omits adsense slots outside development when slot ids are unset' do
    get fiction_url(@fiction)

    assert_response :success
    assert_select '.fiction-show__ad .reader-ad-slot', count: 0
  end

  test 'show renders main and sidebar adsense slot previews in development when slot ids are unset' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      get fiction_url(@fiction)
    end

    assert_response :success
    assert_select '.fiction-show__ad--main #adsense-slot-fiction_show-' \
                  "#{@fiction.id}.reader-ad-slot--preview", count: 1
    assert_select '.fiction-show__ad--sidebar #adsense-slot-fiction_show_sidebar-' \
                  "#{@fiction.id}.reader-ad-slot--preview", count: 1
  end

  test 'production omits adsense on copyright-excluded fiction show' do
    @fiction.update!(slug: FictionsController::AD_EXCLUDED_SLUGS.first)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      get fiction_url(@fiction)
    end

    assert_response :success
    assert_select 'body[data-load-adsense="false"]', count: 1
    assert_select '.fiction-show__ad .reader-ad-slot', count: 0
  end
end
