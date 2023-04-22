# frozen_string_literal: true

require 'telegram/bot'

module TelegramBot
  class << self
    attr_accessor :bot

    def init
      @bot ||= Telegram::Bot::Client.new(ENV.fetch('TELEGRAM_KEY'))
    end
  end
end
