# frozen_string_literal: true

module Chapters
  # Builds denormalized word_count, excerpt and body_bytes from a chapter's loaded Action Text.
  class ContentStats
    EXCERPT_LENGTH = 300

    def self.attributes_for(chapter)
      rich = chapter.content
      html = rich&.body&.to_html.to_s
      plain = rich&.to_plain_text.to_s

      {
        word_count: WordCount.call(plain),
        body_bytes: html.bytesize,
        excerpt: plain.squish.truncate(EXCERPT_LENGTH).presence
      }
    end
  end
end
