# frozen_string_literal: true

require 'test_helper'

module Ui
  class MiniProgressBarComponentTest < ViewComponentTestCase
    test 'partial progress fills the brand bar proportionally' do
      render_inline(MiniProgressBarComponent.new(read: 85, total: 106, html: { aria: { label: '85 з 106' } }))

      assert_selector 'span[role="progressbar"][aria-valuenow="85"][aria-valuemax="106"][aria-label="85 з 106"]'
      assert_selector 'span.bg-line span.bg-brand[style="width: 80.2%"]'
      assert_no_selector 'svg'
    end

    test 'complete progress turns green and shows a check' do
      render_inline(MiniProgressBarComponent.new(read: 107, total: 107))

      assert_selector 'span.bg-status-success-solid[style="width: 100.0%"]'
      assert_selector 'span.text-status-success-solid svg'
    end

    test 'the check can be turned off' do
      render_inline(MiniProgressBarComponent.new(read: 5, total: 5, check: false))

      assert_selector 'span.bg-status-success-solid'
      assert_no_selector 'svg'
    end

    test 'licensed tone stays purple even when complete' do
      render_inline(MiniProgressBarComponent.new(read: 163, total: 163, tone: :licensed))

      assert_selector 'span.bg-status-licensed-solid'
      assert_no_selector 'span.bg-status-success-solid'
      assert_no_selector 'svg'
    end

    test 'clamps read to the total and handles an empty total' do
      render_inline(MiniProgressBarComponent.new(read: 12, total: 10))

      assert_selector '[aria-valuenow="10"] span[style="width: 100.0%"]'

      render_inline(MiniProgressBarComponent.new(read: 0, total: 0))

      assert_selector '[aria-valuenow="0"] span.bg-brand[style="width: 0%"]'
    end

    test 'merges html class' do
      render_inline(MiniProgressBarComponent.new(read: 1, total: 2, html: { class: 'w-60' }))

      assert_selector 'span.w-60[role="progressbar"]'
    end

    test 'rejects unknown tone' do
      assert_raises(ArgumentError) { MiniProgressBarComponent.new(read: 1, total: 2, tone: :danger) }
    end
  end
end
