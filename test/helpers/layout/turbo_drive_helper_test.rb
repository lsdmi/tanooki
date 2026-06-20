# frozen_string_literal: true

require 'test_helper'

module Layout
  class TurboDriveHelperTest < ActionView::TestCase
    include TurboDriveHelper

    test 'turbo_drive_visit_data escapes frames for full-page Drive' do
      assert_equal({ data: { turbo_frame: '_top' } }, turbo_drive_visit_data)
    end

    test 'turbo_drive_visit_data adds preload when requested' do
      assert_equal(
        { data: { turbo_frame: '_top', turbo_preload: true } },
        turbo_drive_visit_data(preload: true)
      )
    end

    test 'turbo_drive_visit_data omits frame escape when frame is nil' do
      assert_equal({ data: {} }, turbo_drive_visit_data(frame: nil))
    end

    test 'turbo_drive_visit_data targets a specific turbo frame' do
      assert_equal(
        { data: { turbo_frame: 'fiction-list-page' } },
        turbo_drive_visit_data(frame: 'fiction-list-page')
      )
    end

    test 'turbo_drive_visit_data can preload without frame escape' do
      assert_equal(
        { data: { turbo_preload: true } },
        turbo_drive_visit_data(preload: true, frame: nil)
      )
    end

    test 'turbo_browse_link_data enables plain Drive without frame override' do
      assert_equal({ data: {} }, turbo_browse_link_data)
    end

    test 'turbo_browse_link_data adds preload when requested' do
      assert_equal(
        { data: { turbo_preload: true } },
        turbo_browse_link_data(preload: true)
      )
    end
  end
end
