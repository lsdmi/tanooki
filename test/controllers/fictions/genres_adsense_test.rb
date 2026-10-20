# frozen_string_literal: true

require 'test_helper'

module Fictions
  class GenresAdsenseTest < ActionDispatch::IntegrationTest
    test 'show omits adsense slots outside development' do
      get fiction_genre_fictions_url(genres(:one).slug)

      assert_response :success
      assert_select 'section.index-banners', count: 0
      assert_select '.adsense-collapse-safe', count: 0
    end

    test 'show renders one banner row with two columns in development' do
      visit_show_in_development

      assert_select 'section.index-banners[aria-label="Реклама"]', count: 1
      assert_select '.index-banners__slot', count: 2
    end

    test 'show keeps the top and mid units as the left and right columns' do
      visit_show_in_development

      assert_select '.index-banners__slot:nth-child(1) #adsense-slot-genres_show_top-top', count: 1
      assert_select '.index-banners__slot:nth-child(1) #adsense-slot-genres_show_mid-mid', count: 0
      assert_select '.index-banners__slot:nth-child(2) #adsense-slot-genres_show_mid-mid', count: 1
    end

    test 'show no longer renders the standalone collapse-safe wrappers' do
      visit_show_in_development

      assert_select '.adsense-collapse-safe', count: 0
    end

    private

    def visit_show_in_development
      Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
        get fiction_genre_fictions_url(genres(:one).slug)
      end

      assert_response :success
    end
  end
end
