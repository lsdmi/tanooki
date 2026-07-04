# frozen_string_literal: true

module Chapters
  # Normalizes chapter HTML for the reader so pasted non-breaking spaces do not
  # create horizontal overflow on narrow viewports.
  class ReaderContentHtml
    NBSP_PATTERN = /&(nbsp|#160|#x0?A0);/i

    def self.render(chapter)
      new(chapter).render
    end

    def self.normalize(html)
      html.to_s.gsub(NBSP_PATTERN, ' ').tr("\u00A0", ' ')
    end

    def initialize(chapter)
      @chapter = chapter
    end

    def render
      self.class.normalize(@chapter.content.to_s)
    end
  end
end
