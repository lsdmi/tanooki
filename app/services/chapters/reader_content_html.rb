# frozen_string_literal: true

module Chapters
  # Prepares chapter HTML for the reader: pasted non-breaking spaces become regular spaces so they do not
  # create horizontal overflow on narrow viewports, and text blocks are tagged for resume (see ReaderBlocks).
  class ReaderContentHtml
    NBSP_PATTERN = /&(nbsp|#160|#x0?A0);/i

    def self.render(chapter)
      new(chapter).render
    end

    def self.normalize(html)
      html.to_s.gsub(NBSP_PATTERN, ' ').tr("\u00A0", ' ')
    end

    # A stored block index is only trusted while the digest still matches.
    delegate :digest, to: :blocks

    def initialize(chapter)
      @chapter = chapter
    end

    def render
      blocks.html
    end

    private

    def blocks
      @blocks ||= ReaderBlocks.new(self.class.normalize(@chapter.content.to_s))
    end
  end
end
