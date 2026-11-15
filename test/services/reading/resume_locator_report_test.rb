# frozen_string_literal: true

require 'test_helper'

module Reading
  class ResumeLocatorReportTest < ActiveSupport::TestCase
    test 'from_report_anchor builds a locator without percent' do
      digest = 'ab' * 8
      locator = ResumeLocator.from_report_anchor(quote: '  Цитата  ', block_index: '2', digest:)

      assert_equal ['Цитата', 2, nil, digest],
                   [locator.quote, locator.block_index, locator.percent, locator.digest]
    end

    test 'from_report_anchor returns nil without quote or index' do
      assert_nil ResumeLocator.from_report_anchor(quote: ' ', block_index: nil, digest: 'ab' * 8)
    end
  end
end
