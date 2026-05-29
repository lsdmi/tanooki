# frozen_string_literal: true

require 'telegram/bot'

# Retry policy for Telegram Bot API jobs.
module TelegramApiJob
  extend ActiveSupport::Concern
  include ExternalApiResilience

  included do
    retry_on Telegram::Bot::Exceptions::ResponseError, wait: :polynomially_longer, attempts: 5
  end
end
