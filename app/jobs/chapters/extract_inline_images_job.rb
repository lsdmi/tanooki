# frozen_string_literal: true

module Chapters
  # Moves base64 images left in a saved chapter body into storage (see ExtractInlineImages).
  class ExtractInlineImagesJob < ApplicationJob
    # Peak memory is about twice the body; larger bodies are left for a local pass.
    MAX_BODY_BYTES = 16.megabytes

    queue_as :heavy
    limits_concurrency key: ->(chapter_id) { chapter_id }, to: 1, duration: 15.minutes
    discard_on ActiveRecord::RecordNotFound

    def perform(chapter_id)
      body_bytes = body_bytes(chapter_id)
      return if body_bytes.nil? || too_large?(chapter_id, body_bytes)

      result = ExtractInlineImages.call(chapter_id)
      Rails.logger.info(
        "[ChapterImages] chapter=#{chapter_id} status=#{result.status} extracted=#{result.extracted} " \
        "failed=#{result.failed} bytes=#{result.before_bytes}->#{result.after_bytes}"
      )
    end

    private

    def too_large?(chapter_id, body_bytes)
      return false if body_bytes <= MAX_BODY_BYTES

      Rails.logger.warn("[ChapterImages] chapter=#{chapter_id} body=#{body_bytes} too large; skipped")
      true
    end

    def body_bytes(chapter_id)
      ActionText::RichText.where(record_type: 'Chapter', record_id: chapter_id, name: 'content')
                          .pick(Arel.sql('LENGTH(body)'))
    end
  end
end
