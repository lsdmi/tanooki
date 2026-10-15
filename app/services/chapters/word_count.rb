# frozen_string_literal: true

module Chapters
  # Counts words in plain chapter text for contests and listings (letters, digits, apostrophes, hyphens).
  class WordCount
    TOKEN = /[\p{L}\p{N}'’ʼ-]+/

    def self.call(plain_text) = plain_text.to_s.scan(TOKEN).size
  end
end
