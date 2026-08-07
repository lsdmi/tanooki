# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ShowCacheHelperTest < ActionView::TestCase
    include ShowCacheHelper
    include Layout::AdultContentHelper

    setup do
      @fiction = fictions(:one)
      @presenter = FictionShowPresenter.new(@fiction, nil, { order: :asc })
      define_singleton_method(:cookies) { {} }
      define_singleton_method(:current_user) { nil }
      define_singleton_method(:session) { {} }
    end

    test 'guest_fiction_show_fragment_cacheable? is true without a signed-in user' do
      assert_predicate self, :guest_fiction_show_fragment_cacheable?
    end

    test 'guest_fiction_show_fragment_cacheable? is false for signed-in users' do
      define_singleton_method(:current_user) { users(:user_one) }

      assert_not guest_fiction_show_fragment_cacheable?
    end

    test 'guest_fiction_show_fragment_cache_key includes fiction order' do
      key = guest_fiction_show_fragment_cache_key(@fiction, @presenter)
      expected = ['fiction_show/v2/guest', @fiction, :asc, I18n.locale, 'light', false]

      assert_equal expected, key.first(6)
      assert_kind_of Integer, key.last
    end

    test 'guest_fiction_show_fragment_cache_key varies with adult content acknowledgement' do
      unacked_key = guest_fiction_show_fragment_cache_key(@fiction, @presenter)

      define_singleton_method(:session) { { adult_content_ack: true } }
      acked_key = guest_fiction_show_fragment_cache_key(@fiction, @presenter)

      assert_not_equal unacked_key, acked_key
    end
  end
end
