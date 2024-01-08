# frozen_string_literal: true

class TelegramJob < ApplicationJob
  queue_as :default

  def perform(object:)
    return unless Rails.env.production?

    TelegramBot.client.api.send_message(
      chat_id: '@bakaInUa',
      text: object.telegram_message,
      parse_mode: 'HTML'
    )
  end
end
