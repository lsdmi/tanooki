# frozen_string_literal: true

require 'telegram/bot'

module TelegramBot
  class << self
    def client
      @client ||= Telegram::Bot::Client.new(ENV.fetch('TELEGRAM_KEY'))
    end
  end
end
