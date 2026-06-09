# frozen_string_literal: true

module Meta
  # Plain-text excerpts for meta descriptions.
  module ExcerptHelper
    SENTENCE_BOUNDARY = /(?<=[.?!])\s+/

    def first_sentence(text)
      text.to_s.split(SENTENCE_BOUNDARY).first.presence || text.to_s
    end
  end
end
