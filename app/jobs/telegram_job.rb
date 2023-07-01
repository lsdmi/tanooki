# frozen_string_literal: true

class TelegramJob < ApplicationJob
  queue_as :default

  attr_reader :object

  def perform(object:)
    return unless Rails.env.production?

    @object = object

    TelegramBot.init
    TelegramBot.bot.api.send_message(
      chat_id: '@bakaInUa',
      text: object.telegram_message,
      parse_mode: 'HTML'
    )
  end
end
