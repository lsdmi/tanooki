# frozen_string_literal: true

require 'test_helper'

module WeeklyDigests
  class MessageRendererTest < ActiveSupport::TestCase
    include WeeklyDigestFixtureHelpers

    setup do
      @wednesday = Time.zone.parse('2026-05-07 14:00')
      travel_to @wednesday do
        seed_weekly_digest_fixture_data!
        @message = MessageRenderer.new(stats: Stats.build(now: @wednesday)).call
      end
    end

    test 'renders weekly chapter count section' do
      assert_includes @message, "з'явилося <b>2</b> нових розділів"
    end

    test 'renders weekly highlight sections' do
      assert_includes @message, 'топ-розділ тижня'
      assert_includes @message, 'ранобе тижня'
      assert_includes @message, 'варте уваги'
    end

    test 'renders support footer' do
      assert_includes @message, 'buymeacoffee'
    end
  end
end
