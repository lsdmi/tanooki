# frozen_string_literal: true

module Books
  # Daily: destroy expired EPUB export requests and their files (config/recurring.yml).
  class PurgeExpiredEpubExportsJob < ApplicationJob
    queue_as :default

    def perform
      result = PurgeExpiredEpubExports.call
      Rails.logger.info("[PurgeExpiredEpubExportsJob] purged=#{result.purged} errors=#{result.errors.size}")
      raise BatchErrors, "#{result.errors.size} exports failed: #{result.errors.first(5)}" if result.errors.any?
    end
  end
end
