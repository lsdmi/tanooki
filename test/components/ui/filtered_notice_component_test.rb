# frozen_string_literal: true

require 'test_helper'

module Ui
  class FilteredNoticeComponentTest < ViewComponentTestCase
    test 'a positive count names how many works the settings hid' do
      render_inline(FilteredNoticeComponent.new(count: 2, change_path: '/studio?tab=profile'))

      assert_selector 'p[role="status"]', text: I18n.t('content_filters.hidden_count', count: 2)
      assert_selector 'a[href="/studio?tab=profile"][data-turbo-frame="_top"]', text: 'Змінити'
    end

    test 'an unknown count says some results are hidden' do
      render_inline(FilteredNoticeComponent.new(count: nil, change_path: '/fictions/alphabetical'))

      assert_selector 'p[role="status"]', text: I18n.t('content_filters.some_hidden')
    end

    test 'a zero count renders nothing' do
      render_inline(FilteredNoticeComponent.new(count: 0, change_path: '/studio?tab=profile'))

      assert_no_selector 'p'
    end
  end
end
