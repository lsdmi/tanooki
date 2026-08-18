# frozen_string_literal: true

require 'test_helper'

module TelegramDigests
  class FictionsTest < ActiveSupport::TestCase
    test 'call sends message in production when there are recent fictions' do
      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        expected_text = Fictions.new.text_message
        sent = capture_send { Fictions.call }

        assert_equal(
          { chat_id: '@bakaInUa', text: expected_text, parse_mode: 'HTML' },
          sent
        )
      end
    end

    private

    def capture_send(&)
      slot = []
      api = Minitest::Mock.new
      api.expect(:send_message, nil) { |params| slot[0] = params }
      bot = Minitest::Mock.new
      bot.expect(:api, api)
      TelegramBot.stub(:client, bot, &)
      api.verify && bot.verify
      slot[0]
    end
  end
end
