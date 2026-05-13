# frozen_string_literal: true

require 'telegram/bot'

# Lazily builds a Telegram Bot API client using +TELEGRAM_KEY+ from the environment.
module TelegramBot
  class << self
    def client
      @client ||= Telegram::Bot::Client.new(ENV.fetch('TELEGRAM_KEY'))
    end
  end
end
