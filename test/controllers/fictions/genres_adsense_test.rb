# frozen_string_literal: true

require 'test_helper'

module Fictions
  class GenresAdsenseTest < ActionDispatch::IntegrationTest
    test 'show omits adsense slots outside development' do
      get fiction_genre_fictions_url(genres(:one).slug)

      assert_response :success
      assert_select '.adsense-collapse-safe', count: 0
    end

    test 'show renders adsense slot previews in development' do
      Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
        get fiction_genre_fictions_url(genres(:one).slug)
      end

      assert_response :success
      assert_select '.adsense-collapse-safe #adsense-slot-genres_show_top-top.reader-ad-slot--preview',
                    count: 1
      assert_select '.adsense-collapse-safe #adsense-slot-genres_show_mid-mid.reader-ad-slot--preview',
                    count: 1
    end
  end
end
