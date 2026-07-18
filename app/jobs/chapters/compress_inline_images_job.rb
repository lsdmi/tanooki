# frozen_string_literal: true

module Chapters
  # Background repair for chapters with Word-pasted inline base64 images.
  class CompressInlineImagesJob < ApplicationJob
    queue_as :default

    def perform(chapter_id)
      result = CompressInlineImages.call(chapter_id)
      log_result(result)
      result
    end

    private

    def log_result(result)
      Rails.logger.info(
        "[CompressInlineImagesJob] chapter=#{result.chapter_id} rich_text=#{result.rich_text_id} " \
        "compressed=#{result.images_compressed} bytes=#{result.before_bytes}->#{result.after_bytes} " \
        "unchanged=#{result.unchanged}"
      )
    end
  end
end
