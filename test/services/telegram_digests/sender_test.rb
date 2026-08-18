# frozen_string_literal: true

require 'test_helper'

module TelegramDigests
  class SenderTest < ActiveSupport::TestCase
    teardown do
      ENV.delete('TELEGRAM_CHAT_ID')
    end

    test 'chat_id defaults to production channel' do
      assert_equal '@bakaInUa', Sender.chat_id
    end

    test 'chat_id uses TELEGRAM_CHAT_ID when set' do
      ENV['TELEGRAM_CHAT_ID'] = '@bakaTgTest'

      assert_equal '@bakaTgTest', Sender.chat_id
    end
  end
end
