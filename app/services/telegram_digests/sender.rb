# frozen_string_literal: true

require 'telegram/bot'

module TelegramDigests
  # Posts HTML digests to Telegram with a few retries on API errors.
  # Default channel is @bakaInUa; override with TELEGRAM_CHAT_ID (e.g. @bakaTgTest).
  class Sender
    DEFAULT_CHAT_ID = '@bakaInUa'
    ATTEMPTS = 5

    def self.call(text)
      new(text).call
    end

    def self.chat_id
      ENV.fetch('TELEGRAM_CHAT_ID', DEFAULT_CHAT_ID)
    end

    def initialize(text)
      @text = text
    end

    def call
      attempt = 0
      begin
        attempt += 1
        TelegramBot.client.api.send_message(chat_id: self.class.chat_id, text: @text, parse_mode: 'HTML')
      rescue Telegram::Bot::Exceptions::ResponseError
        raise if attempt >= ATTEMPTS

        sleep(attempt)
        retry
      end
    end
  end
end
