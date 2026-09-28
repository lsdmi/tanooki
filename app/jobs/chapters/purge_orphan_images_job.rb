# frozen_string_literal: true

module Chapters
  # Daily: purges chapter image blobs no chapter links to anymore. The grace period covers
  # editors left open and TinyMCE autosave drafts that are restored days later.
  # Soft-deleted attachments (a soft-deleted chapter) still count, so a restored chapter keeps its images.
  class PurgeOrphanImagesJob < ApplicationJob
    GRACE_PERIOD = 7.days

    queue_as :default

    def perform
      purged = 0
      self.class.orphans.find_each do |blob|
        purge(blob)
        purged += 1
      end
      Rails.logger.info("[ChapterImages] purged #{purged} orphan blob(s)")
    end

    # Blobs are soft-deletable in this app, so rows an earlier blob.purge only hid are included.
    def self.orphans
      ActiveStorage::Blob.with_deleted
                         .where(service_name: Images.service_name)
                         .where(created_at: ...GRACE_PERIOD.ago)
                         .where.not(id: ActiveStorage::Attachment.with_deleted.select(:blob_id))
    end

    private

    # blob.purge would only soft-delete the row and leave the file on the service.
    def purge(blob)
      blob.service.delete(blob.key)
      blob.really_destroy!
    end
  end
end
