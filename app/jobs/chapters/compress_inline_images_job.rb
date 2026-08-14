# frozen_string_literal: true

module Chapters
  # Background repair for chapters with Word-pasted inline base64 images.
  # Serialized to one job at a time so vips work cannot OOM the worker container.
  class CompressInlineImagesJob < ApplicationJob
    queue_as :compress

    # Global cap across all chapter compress work (Solid Queue blocked executions).
    limits_concurrency to: 1, key: 'chapters_compress_inline_images', duration: 1.hour

    def perform(chapter_id)
      result = CompressInlineImages.call(chapter_id)
      log_result(result)
      result
    ensure
      GC.start
    end

    private

    def log_result(result)
      Rails.logger.info(
        "[CompressInlineImagesJob] chapter=#{result.chapter_id} rich_text=#{result.rich_text_id} " \
        "compressed=#{result.images_compressed} bytes=#{result.before_bytes}->#{result.after_bytes} " \
        "unchanged=#{result.unchanged} skipped=#{result.skipped_reason || 'none'}"
      )
    end
  end
end
