# frozen_string_literal: true

namespace :chapters do
  desc 'Compress oversized inline images in a chapter rich text (CHAPTER_ID=34745)'
  task compress_inline_images: :environment do
    chapter_id = ENV.fetch('CHAPTER_ID')
    result = Chapters::CompressInlineImages.call(chapter_id)

    puts "chapter_id=#{result.chapter_id} rich_text_id=#{result.rich_text_id}"
    puts "images_compressed=#{result.images_compressed} unchanged=#{result.unchanged}"
    puts "bytes=#{result.before_bytes}->#{result.after_bytes}"
  end

  desc 'Compress inline images for chapters posted yesterday (CI / laptop)'
  task compress_recent: :environment do
    day = ENV['DAY'].present? ? Date.parse(ENV.fetch('DAY')) : Time.current.to_date
    result = Chapters::CompressRecent.call(day:)

    puts "day=#{result.day} targets=#{result.chapter_ids.size} " \
         "compressed=#{result.compressed} unchanged=#{result.unchanged} errors=#{result.errors.size}"
    result.errors.each { |error| puts "  chapter=#{error[:chapter_id]} #{error[:error]}" }

    abort 'chapters:compress_recent failed' if result.errors.any?
  end
end
