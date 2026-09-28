# frozen_string_literal: true

module Chapters
  # After a chapter save: attachment rows follow the images the body links to, and any
  # image still inline as base64 is queued to move into storage.
  # Attachment rows are created and deleted directly: `attach` would save the chapter
  # (old chapters fail validations) and purging could remove a blob another chapter links.
  class SyncImages
    def self.call(chapter)
      new(chapter).call
    end

    def initialize(chapter)
      @chapter = chapter
    end

    def call
      rich_text = @chapter.rich_text_content
      html = rich_text&.read_attribute_before_type_cast(:body).to_s
      sync_attachments(html)
      return unless html.include?(ContentLimits::BASE64_MARKER) && rich_text.saved_change_to_body?

      ExtractInlineImagesJob.perform_later(@chapter.id)
    end

    private

    def sync_attachments(html)
      linked = Images.blobs_in(html).pluck(:id)
      attached = @chapter.images_attachments.pluck(:blob_id)
      (linked - attached).each { |blob_id| @chapter.images_attachments.create!(blob_id:) }
      stale = attached - linked
      @chapter.images_attachments.where(blob_id: stale).delete_all if stale.any?
    end
  end
end
