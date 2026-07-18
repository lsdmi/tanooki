# frozen_string_literal: true

namespace :chapters do
  desc 'Compress oversized inline images in a chapter rich text (CHAPTER_ID=34745)'
  task compress_inline_images: :environment do
    chapter_id = ENV.fetch('CHAPTER_ID')
    result = Chapters::CompressInlineImagesJob.perform_now(chapter_id)

    puts "chapter_id=#{result.chapter_id} rich_text_id=#{result.rich_text_id}"
    puts "images_compressed=#{result.images_compressed} unchanged=#{result.unchanged}"
    puts "bytes=#{result.before_bytes}->#{result.after_bytes}"
  end
end
