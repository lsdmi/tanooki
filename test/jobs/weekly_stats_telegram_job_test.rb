# frozen_string_literal: true

require 'test_helper'

class WeeklyStatsTelegramJobTest < ActiveSupport::TestCase
  include WeeklyDigestFixtureHelpers

  setup do
    @wednesday = Time.zone.parse('2026-05-07 14:00')
  end

  test 'perform sends weekly digest HTML to Telegram' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      travel_to @wednesday do
        seed_weekly_digest_fixture_data!
        expected_text = WeeklyDigests::MessageRenderer.new(stats: WeeklyDigests::Stats.build(now: @wednesday)).call
        sent = capture_telegram_weekly_send

        assert_equal(
          { chat_id: '@bakaInUa', text: expected_text, parse_mode: 'HTML' },
          sent
        )
      end
    end
  end

  private

  def capture_telegram_weekly_send
    slot = []
    api = Minitest::Mock.new
    api.expect(:send_message, nil) { |p| slot[0] = p }
    bot = Minitest::Mock.new
    bot.expect(:api, api)
    TelegramBot.stub(:client, bot) { WeeklyStatsTelegramJob.new.perform }
    api.verify && bot.verify
    slot[0]
  end
end
