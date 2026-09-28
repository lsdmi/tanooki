# frozen_string_literal: true

module TelegramDigests
  # Weekly channel posts, one schedule per digest (config/recurring.yml).
  # Never retried automatically: a retry after a sent message would post twice.
  class PostJob < ApplicationJob
    queue_as :default

    def perform(digest)
      Post.call(digest)
      Rails.logger.info("[TelegramDigests::PostJob] digest=#{digest} chat=#{Sender.chat_id} posted")
    end
  end
end
