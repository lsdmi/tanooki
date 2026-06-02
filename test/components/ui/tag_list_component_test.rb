# frozen_string_literal: true

require 'test_helper'

module Ui
  class TagListComponentTest < ViewComponentTestCase
    test 'renders nothing when labels empty' do
      render_inline(TagListComponent.new(labels: []))

      assert_no_selector 'a, span'
    end

    test 'renders tags with href builder' do
      render_inline(
        TagListComponent.new(
          labels: %w[аніме fantasy],
          variant: :keyword,
          href_builder: ->(label) { "/search?q=#{label}" },
          current_label: 'аніме'
        )
      )

      assert_selector 'a', count: 2
      assert_selector 'a.bg-cyan-700', count: 1
      assert_selector 'a.border-gray-300', count: 1
    end

    test 'passes counts to tags' do
      render_inline(
        TagListComponent.new(
          labels: %w[аніме empty],
          counts: { 'аніме' => 12, 'empty' => 0 }
        )
      )

      assert_selector 'span', text: '12'
      assert_no_selector 'span', text: '0'
    end

    test 'renders 18+ as adult tag without link' do
      render_inline(
        TagListComponent.new(
          labels: ['18+', 'Драма'],
          variant: :genre,
          genre_slugs: { 'Драма' => 'drama' },
          href_builder: ->(name) { "/genres/#{name}" unless name == '18+' }
        )
      )

      assert_selector 'span.bg-orange-600', text: '18+'
      assert_selector 'span.bg-orange-600 svg'
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

    test 'uses adult variant for explicit genres when variant is genre' do
      render_inline(
        TagListComponent.new(
          labels: %w[BL Драма],
          variant: :genre,
          genre_slugs: { 'BL' => 'bl', 'Драма' => 'drama' },
          href_builder: ->(label) { "/fictions/genres/#{label}" }
        )
      )

      assert_selector 'a.bg-orange-600', text: 'BL'
      assert_selector 'a.bg-orange-600 svg'
      assert_selector 'a.border-gray-300', text: 'Драма'
    end

    test 'renders overflow tag when max exceeded' do
      render_inline(
        TagListComponent.new(
          labels: %w[one two three four five],
          variant: :keyword,
          max: 3,
          href_builder: ->(label) { "/search?q=#{label}" }
        )
      )

      assert_selector 'a', count: 3
      assert_selector 'span', text: '+2'
    end
  end
end
