# frozen_string_literal: true

require 'test_helper'

module Ui
  class TagListComponentRatingTest < ViewComponentTestCase
    test 'renders 18+ as eighteen rating tag without link' do
      render_inline(
        TagListComponent.new(
          labels: ['18+', 'Драма'],
          variant: :genre,
          genre_slugs: { 'Драма' => 'drama' },
          href_builder: ->(name) { "/genres/#{name}" unless Genre.rating_tag?(name) }
        )
      )

      assert_selector 'span.bg-rose-200', text: '18+'
      assert_selector 'span.bg-rose-200 svg'
      assert_selector 'a.border-gray-300', text: 'Драма'
    end

    test 'renders 16+ as amber rating tag without link' do
      render_inline(
        TagListComponent.new(
          labels: ['16+', 'Драма'],
          variant: :genre,
          genre_slugs: { 'Драма' => 'drama' },
          href_builder: ->(name) { "/genres/#{name}" unless Genre.rating_tag?(name) }
        )
      )

      assert_selector 'span.bg-amber-200', text: '16+'
      assert_selector 'span.bg-amber-200 svg'
      assert_selector 'a.border-gray-300', text: 'Драма'
    end

    test 'sort_adult_first orders red tags before outline tags' do
      render_inline(
        TagListComponent.new(
          labels: %w[Романтика 18+ Драма BL],
          variant: :genre,
          sort_adult_first: true,
          genre_slugs: { 'BL' => 'bl', 'Драма' => 'drama', 'Романтика' => 'romance' }
        )
      )

      assert_text(/18\+.*BL.*Романтика.*Драма/m)
    end
  end
end
