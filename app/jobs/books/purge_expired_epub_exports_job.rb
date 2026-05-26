# frozen_string_literal: true

module Books
  # Removes expired EPUB export requests and their attached files.
  class PurgeExpiredEpubExportsJob < ApplicationJob
    queue_as :default

    def perform
      EpubExportRequest.expired.find_each(&:destroy!)
    end
  end
end
