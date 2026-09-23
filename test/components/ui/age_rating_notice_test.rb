# frozen_string_literal: true

require 'test_helper'

module Ui
  class AgeRatingNoticeTest < ViewComponentTestCase
    test 'renders sixteen notice with amber styles' do
      render_inline(AgeRatingNotice.new(rating: :sixteen))

      assert_text I18n.t('fictions.age_rating_notice.sixteen.title')
      assert_selector 'section.bg-amber-100.border-amber-800'
      assert_selector '[data-age-rating-notice-rating-value="sixteen"]'
    end

    test 'sixteen notice skips the eighteen disclaimer stylesheet classes' do
      render_inline(AgeRatingNotice.new(rating: :sixteen))

      assert_no_selector '.adult-content-disclaimer'
    end

    test 'renders eighteen notice with adult disclaimer classes' do
      render_inline(AgeRatingNotice.new(rating: :eighteen, reader_gate: true))

      assert_text I18n.t('fictions.age_rating_notice.eighteen.reader_title')
      assert_selector 'section.adult-content-disclaimer'
      assert_selector '[data-age-rating-notice-rating-value="eighteen"]'
    end

    test 'rejects unknown rating' do
      assert_raises(ArgumentError) do
        AgeRatingNotice.new(rating: :twelve)
      end
    end
  end
end
