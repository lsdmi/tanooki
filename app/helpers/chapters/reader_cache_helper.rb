# frozen_string_literal: true

module Chapters
  # Fragment cache key for the rendered reader body. Uses denormalized body_bytes (Stream 4) so a
  # cache hit does not load action_text_rich_texts just to read updated_at.
  module ReaderCacheHelper
    def chapter_reader_body_cache_key(chapter)
      ['chapter_reader/v2', chapter.id, chapter.updated_at.to_i, chapter.body_bytes, I18n.locale]
    end
  end
end
