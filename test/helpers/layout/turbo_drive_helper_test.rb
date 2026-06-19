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
  end
end
