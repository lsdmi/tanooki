# frozen_string_literal: true

module Books
  # Checks whether requested chapters are allowed to be exported as EPUB.
  class EpubDownloadPermission
    def self.allowed?(chapters)
      new(chapters).allowed?
    end

    def initialize(chapters)
      @chapters = Array(chapters)
    end

    def allowed?
      chapters.any? && chapters.all? { |chapter| chapter.scanlators.all?(&:convertable?) }
    end

    private

    attr_reader :chapters
  end
end
