# frozen_string_literal: true

require 'test_helper'

module Layout
  class AdultContentHelperTest < ActionView::TestCase
    include AdultContentHelper

    setup do
      @everyone = fictions(:one)
      @sixteen = fictions(:two)
      @eighteen = fictions(:eighteen)
      define_singleton_method(:current_user) { nil }
      define_singleton_method(:session) { {} }
    end

    test 'show_age_rating_notice? is false for everyone' do
      assert_not show_age_rating_notice?(@everyone)
    end

    test 'sixteen notice shows until 18+ is acknowledged and is never a reader gate' do
      assert show_age_rating_notice?(@sixteen)
      assert_equal :sixteen, age_rating_notice_rating(@sixteen)
      assert_not age_rating_reader_gate?(@sixteen)
    end

    test 'eighteen notice shows until acknowledged' do
      assert show_age_rating_notice?(@eighteen)
      assert_equal :eighteen, age_rating_notice_rating(@eighteen)
      assert age_rating_reader_gate?(@eighteen)
    end

    test 'eighteen acknowledgement hides both sixteen and eighteen notices' do
      define_singleton_method(:session) { { adult_content_ack: true } }

      assert_not show_age_rating_notice?(@eighteen)
      assert_not age_rating_reader_gate?(@eighteen)
      assert_not show_age_rating_notice?(@sixteen)
    end
  end
end
