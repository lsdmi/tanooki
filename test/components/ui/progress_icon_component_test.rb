# frozen_string_literal: true

require 'test_helper'

module Ui
  class ProgressIconComponentTest < ViewComponentTestCase
    test 'each state has its own token color and shape' do
      render_inline(ProgressIconComponent.new(state: :unread))

      assert_selector 'span.text-fg-muted svg circle[r="10"]'

      render_inline(ProgressIconComponent.new(state: :in_progress))

      assert_selector 'span.text-fg-brand svg path', count: 8

      render_inline(ProgressIconComponent.new(state: :read))

      assert_selector 'span.text-status-success-solid svg path', count: 2
    end

    test 'sizes map to 16, 20 and 24 px and default to 20' do
      render_inline(ProgressIconComponent.new(state: :read))

      assert_selector 'span.size-5'

      render_inline(ProgressIconComponent.new(state: :read, size: :sm))

      assert_selector 'span.size-4'

      render_inline(ProgressIconComponent.new(state: :read, size: :lg))

      assert_selector 'span.size-6'
    end

    test 'a label makes it an image for screen readers' do
      render_inline(ProgressIconComponent.new(state: :read, label: 'Прочитано'))

      assert_selector 'span[role="img"][aria-label="Прочитано"]'
      assert_no_selector 'span[aria-hidden="true"][role]'
    end

    test 'without a label it is decorative' do
      render_inline(ProgressIconComponent.new(state: :unread))

      assert_selector 'span[aria-hidden="true"]'
      assert_no_selector '[role="img"]'
    end

    test 'merges html class' do
      render_inline(ProgressIconComponent.new(state: :unread, html: { class: 'mt-1' }))

      assert_selector 'span.mt-1.text-fg-muted'
    end

    test 'rejects unknown state and size' do
      assert_raises(ArgumentError) { ProgressIconComponent.new(state: :current) }
      assert_raises(ArgumentError) { ProgressIconComponent.new(state: :read, size: :xl) }
    end
  end
end
