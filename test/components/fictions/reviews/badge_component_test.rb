# frozen_string_literal: true

require 'test_helper'

module Fictions
  module Reviews
    class BadgeComponentTest < ViewComponentTestCase
      test 'marks the comment as a review' do
        render_inline(BadgeComponent.new(rating: 4, read_count: 2))

        assert_text 'Відгук'
      end

      test 'shows the author’s rating as five stars, the filled ones first' do
        render_inline(BadgeComponent.new(rating: 4, read_count: 2))

        assert_selector 'svg.fill-amber-400', count: 4
        assert_selector 'svg.fill-transparent', count: 1
        assert_selector '[role="img"][aria-label="Оцінка: 4 з 5"]'
      end

      test 'omits the stars when the rating is gone' do
        render_inline(BadgeComponent.new(rating: nil, read_count: 2))

        assert_no_selector '[role="img"]'
        assert_text 'Прочитано 2 розділи'
      end

      test 'says how many chapters were read, with Ukrainian plurals' do
        { 1 => 'Прочитано 1 розділ', 2 => 'Прочитано 2 розділи', 5 => 'Прочитано 5 розділів',
          11 => 'Прочитано 11 розділів', 21 => 'Прочитано 21 розділ' }.each do |count, text|
          render_inline(BadgeComponent.new(rating: 5, read_count: count))

          assert_text text
        end
      end

      test 'a reader who read nothing says so' do
        render_inline(BadgeComponent.new(rating: 3, read_count: 0))

        assert_text 'Не прочитав жодного розділу'
        assert_no_text 'Прочитано'
      end
    end
  end
end
