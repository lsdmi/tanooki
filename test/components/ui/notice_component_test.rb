# frozen_string_literal: true

require 'test_helper'

module Ui
  class NoticeComponentTest < ViewComponentTestCase
    test 'light style uses the subtle status colors' do
      render_inline(NoticeComponent.new(kind: :adult, title: 'Контент 18+', body: 'Лише для дорослих.'))

      assert_selector 'div[role="note"].bg-status-danger-subtle-bg svg.size-4.text-status-danger-solid'
      assert_selector 'p.text-status-danger-solid.font-semibold', text: 'Контент 18+'
      assert_selector 'div.text-fg-secondary', text: 'Лише для дорослих.'
    end

    test 'scrim style sits on the hero image with on-media colors' do
      render_inline(NoticeComponent.new(kind: :licensed, style: :scrim, title: 'Офіційна ліцензія', body: 'Текст'))

      assert_selector 'div.bg-overlay-scrim-45.backdrop-blur-lg.border-status-licensed-on-media-border svg.md\\:size-6'
      assert_selector 'p.text-status-licensed-on-media-title', text: 'Офіційна ліцензія'
      assert_selector 'div.text-status-licensed-on-media-fg', text: 'Текст'
    end

    test 'tinted style uses the family on-media background' do
      render_inline(NoticeComponent.new(kind: :teen, style: :tinted, title: 'Контент 16+'))

      assert_selector 'div.bg-status-warning-on-media-bg.border-status-warning-on-media-border'
      assert_no_selector 'div.bg-overlay-scrim-45'
    end

    test 'each kind maps to its status family' do
      { adult: 'danger', teen: 'warning', licensed: 'licensed', dropped: 'warning', announced: 'info',
        finished: 'success' }.each do |kind, family|
        render_inline(NoticeComponent.new(kind:, title: 'Заголовок'))

        assert_selector "div.bg-status-#{family}-subtle-bg"
      end
    end

    test 'renders body from content and an optional action' do
      render_inline(NoticeComponent.new(kind: :licensed, title: 'Ліцензія')) do |notice|
        notice.with_action { '<a href="/official">Офіційне видання</a>'.html_safe }
        '<strong>Видавництво</strong>'.html_safe
      end

      assert_selector 'div strong', text: 'Видавництво'
      assert_selector 'a[href="/official"]', text: 'Офіційне видання'
    end

    test 'keeps the body argument when the block only sets the action' do
      render_inline(NoticeComponent.new(kind: :licensed, title: 'Ліцензія', body: 'Видавництво «А»')) do |notice|
        notice.with_action { '<a href="/official">Офіційне видання</a>'.html_safe }
        "\n  "
      end

      assert_selector 'div', text: 'Видавництво «А»'
    end

    test 'omits the body when none is given' do
      render_inline(NoticeComponent.new(kind: :finished, title: 'Переклад завершено'))

      assert_selector 'p', text: 'Переклад завершено'
      assert_no_selector 'div.text-fg-secondary'
    end

    test 'rejects unknown kind and style' do
      assert_raises(ArgumentError) { NoticeComponent.new(kind: :paused, title: 'X') }
      assert_raises(ArgumentError) { NoticeComponent.new(kind: :adult, title: 'X', style: :banner) }
    end
  end
end
