# frozen_string_literal: true

module Ops
  # Posts an operational alert (HTML) to the ops Telegram channel, never the public one. Outside production it is only
  # logged. Override the channel with TELEGRAM_OPS_CHAT_ID.
  class Alert
    DEFAULT_CHAT_ID = '@bakaTgTest'

    def self.call(text)
      Rails.logger.warn("[Ops::Alert] #{text.squish}")
      return unless Rails.env.production?

      TelegramDigests::Sender.call(text, chat_id: chat_id)
    end

    def self.chat_id
      ENV.fetch('TELEGRAM_OPS_CHAT_ID', DEFAULT_CHAT_ID)
    end
  end
end
