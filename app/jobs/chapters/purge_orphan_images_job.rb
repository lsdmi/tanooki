# frozen_string_literal: true

module Chapters
  # Daily: purges chapter image blobs no chapter links to anymore. The grace period covers
  # editors left open and TinyMCE autosave drafts that are restored days later.
  class PurgeOrphanImagesJob < ApplicationJob
    GRACE_PERIOD = 7.days

    queue_as :default

    def perform
      purged = 0
      self.class.orphans.find_each do |blob|
        blob.purge
        purged += 1
      end
      Rails.logger.info("[ChapterImages] purged #{purged} orphan blob(s)")
    end

    def self.orphans
      ActiveStorage::Blob.where(service_name: Images.service_name)
                         .where(created_at: ...GRACE_PERIOD.ago)
                         .where.missing(:attachments)
    end
  end
end
