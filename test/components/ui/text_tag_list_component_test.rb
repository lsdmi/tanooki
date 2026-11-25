# frozen_string_literal: true

require 'test_helper'

module Ui
  class TextTagListComponentTest < ViewComponentTestCase
    test 'renders nothing without labels' do
      render_inline(TextTagListComponent.new(caption: 'Теґи', labels: []))

      assert_no_selector 'section'
    end

    test 'shows the caption and each tag with a hash' do
      render_inline(TextTagListComponent.new(caption: 'Теґи', labels: %w[Переродження ЛітРПГ]))

      assert_selector 'section[aria-label="Теґи"] > span', text: 'Теґи'
      assert_selector 'section span', text: '#Переродження'
    end

    test 'tags are plain text, not links or chips' do
      render_inline(TextTagListComponent.new(caption: 'Теґи', labels: %w[Переродження]))

      assert_no_selector 'a'
      assert_no_selector '.border'
    end

    test 'a tag with a path becomes a link and keeps the text' do
      builder = ->(label) { "/fictions?tags[]=#{label}" if label == 'Драма' }

      render_inline(TextTagListComponent.new(caption: 'Теґи', labels: %w[Драма Жахи], href_builder: builder))

      assert_selector 'a[href="/fictions?tags[]=Драма"]', text: '#Драма'
      assert_no_selector 'a[href*="Жахи"]'
      assert_selector 'span', text: '#Жахи'
    end

    test 'an 18+ tag gets the warning icon and the danger colour' do
      render_inline(TextTagListComponent.new(caption: 'Теґи', labels: %w[Омегаверс],
                                             explicit_labels: %w[Омегаверс]))

      assert_selector 'span.text-status-danger-solid svg'
      assert_selector 'span.text-status-danger-solid', text: '#Омегаверс'
    end

    test 'other tags keep the secondary colour and get no icon' do
      render_inline(TextTagListComponent.new(caption: 'Теґи', labels: %w[Драма],
                                             explicit_labels: %w[Омегаверс]))

      assert_selector 'span.text-fg-secondary', text: '#Драма'
      assert_no_selector 'svg'
    end

    test 'blank labels are dropped' do
      render_inline(TextTagListComponent.new(caption: 'Теґи', labels: ['', 'Драма', nil]))

      assert_selector 'section > span', count: 2
    end
  end
end
