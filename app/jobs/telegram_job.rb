# frozen_string_literal: true

class TelegramJob < ApplicationJob
  queue_as :default

  def perform(tale)
    return unless Rails.env.production?

    TelegramBot.init
    url = "https://baka.in.ua#{Rails.application.routes.url_helpers.tale_path(tale)}"
    TelegramBot.bot.api.send_message(chat_id: '@bakaInUa', text: url)
  end
end
