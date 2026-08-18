# frozen_string_literal: true

require 'test_helper'

module TelegramDigests
  class YoutubeVideosTest < ActiveSupport::TestCase
    test 'call sends video message in production' do
      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        expected_text = YoutubeVideos.new.text_message
        sent = capture_send { YoutubeVideos.call }

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
