# frozen_string_literal: true

module Text
  # Short plain-text excerpts for cards and meta descriptions.
  module ExcerptHelper
    def punch(string)
      sentences = string.scan(/.*?[.?!](?=\s|\z)/)
      result = ''

      sentences.each do |sentence|
        result.length <= 20 ? result += sentence : break
      end

      result.presence || string
    end
  end
end
