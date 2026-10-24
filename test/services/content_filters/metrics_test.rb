# frozen_string_literal: true

require 'test_helper'

module ContentFilters
  class MetricsTest < ActiveSupport::TestCase
    test 'counts readers who set a rating cap or hid a genre' do
      report = Metrics.call

      assert_operator report.filtered, :>=, 2
      assert_includes report.top.keys, I18n.t('content_filters.packages.shelves.name')
      assert_nil report.guest_no18
    end
  end
end
