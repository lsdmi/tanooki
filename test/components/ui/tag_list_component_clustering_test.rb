# frozen_string_literal: true

require 'test_helper'

module Ui
  class TagListComponentClusteringTest < ViewComponentTestCase
    test 'clusters adult genre tags side by side' do
      render_inline(
        TagListComponent.new(
          labels: %w[BL ЛГБТ Драма],
          variant: :genre,
          sort_adult_first: true,
          genre_slugs: { 'BL' => 'bl', 'ЛГБТ' => 'lgbt', 'Драма' => 'drama' },
          href_builder: ->(name) { "/genres/#{name}" }
        )
      )

      assert_selector 'div.inline-flex.flex-nowrap.items-center.gap-1', count: 1
      assert_selector 'div.inline-flex.flex-nowrap a.bg-rose-200', count: 2
    end

    test 'max prioritizes adult tags before regular genres' do
      render_inline(
        TagListComponent.new(
          labels: %w[Драма BL ЛГБТ Пригоди],
          variant: :genre,
          max: 2,
          sort_adult_first: true,
          genre_slugs: { 'BL' => 'bl', 'ЛГБТ' => 'lgbt', 'Драма' => 'drama', 'Пригоди' => 'adventure' },
          href_builder: ->(name) { "/genres/#{name}" }
        )
      )

      assert_selector 'a.bg-rose-200', text: 'BL'
      assert_selector 'a.bg-rose-200', text: 'ЛГБТ'
    end

    test 'max drops regular genres when adult tags fill the limit' do
      render_inline(
        TagListComponent.new(
          labels: %w[Драма BL ЛГБТ Пригоди],
          variant: :genre,
          max: 2,
          sort_adult_first: true,
          genre_slugs: { 'BL' => 'bl', 'ЛГБТ' => 'lgbt', 'Драма' => 'drama', 'Пригоди' => 'adventure' },
          href_builder: ->(name) { "/genres/#{name}" }
        )
      )

      assert_no_selector 'a', text: 'Драма'
      assert_no_selector 'a', text: 'Пригоди'
    end
  end
end
