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

    test 'sends to the chat it is given' do
      sent = []
      api = Object.new
      api.define_singleton_method(:send_message) { |**params| sent << params }

      TelegramBot.stub(:client, Struct.new(:api).new(api)) { Sender.call('<b>hi</b>', chat_id: '@ops') }

      assert_equal [{ chat_id: '@ops', text: '<b>hi</b>', parse_mode: 'HTML' }], sent
    end
  end
end
