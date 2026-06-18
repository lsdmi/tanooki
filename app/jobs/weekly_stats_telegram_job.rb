# frozen_string_literal: true

# Wednesday digest: stats for this week + highlights from last calendar week (Europe/Kiev).
class WeeklyStatsTelegramJob < ApplicationJob
  include TelegramApiJob

  queue_as :default

  def perform
    return unless Rails.env.production?

    TelegramBot.client.api.send_message(
      chat_id: '@bakaInUa',
      text: WeeklyDigests::MessageRenderer.new.call,
      parse_mode: 'HTML'
    )
  end
end
