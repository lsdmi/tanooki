# frozen_string_literal: true

require 'test_helper'

module Api
  class LimitsUsageTest < ActiveSupport::TestCase
    setup { @user = users(:user_two) }

    teardown do
      Rails.cache.delete(Limits.counter_key(:published_edit_hour, @user, Limits::PublishedEdits.hour_period))
      Rails.cache.delete(Limits.counter_key(:published_edit_span, @user, Limits::PublishedEdits.span_period))
    end

    test 'usage reads the hour counter without charging again' do
      Limits::PublishedEdits.charge!(@user)
      usage = Limits::Usage.snapshot(@user)
      again = Limits::Usage.snapshot(@user)

      assert_equal 1, usage.dig(:published_edits_this_hour, :used)
      assert_equal 59, usage.dig(:published_edits_this_hour, :remaining)
      assert_equal 1, again.dig(:published_edits_this_hour, :used)
    end
  end
end
