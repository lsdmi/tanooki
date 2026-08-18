# frozen_string_literal: true

module TelegramDigests
  # Wednesday CI digest: weekly site stats → @bakaInUa.
  class WeeklyStats
    def self.call
      new.call
    end

    def call
      return unless Rails.env.production?

      Sender.call(WeeklyDigests::MessageRenderer.new.call)
    end
  end
end
