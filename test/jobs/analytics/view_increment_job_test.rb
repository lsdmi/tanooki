# frozen_string_literal: true

require 'test_helper'

module Analytics
  class ViewIncrementJobTest < ActiveJob::TestCase
    test 'increments views for the record' do
      tale = publications(:tale_approved_one)
      tale.update!(views: 0)

      ViewIncrementJob.perform_now('Publication', tale.id)

      assert_equal 1, tale.reload.views
    end

    test 'no-ops when record was deleted' do
      assert_nothing_raised do
        ViewIncrementJob.perform_now('Publication', -1)
      end
    end
  end
end
