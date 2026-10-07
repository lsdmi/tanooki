# frozen_string_literal: true

module Books
  # Checks whether requested chapters are allowed to be exported as EPUB.
  # Every chapter's team must allow conversion, and no chapter may belong to a licensed fiction.
  class EpubDownloadPermission
    def self.allowed?(chapters)
      new(chapters).allowed?
    end

    def initialize(chapters)
      @chapters = Array(chapters)
    end

    def allowed?
      chapters.any? && chapters.all? { |chapter| chapter.scanlators.all?(&:convertable?) } && !licensed_fiction?
    end

    private

    attr_reader :chapters

    # Loaded fictions answer in memory; otherwise one query covers all of them.
    def licensed_fiction?
      fictions = chapters.map { |chapter| chapter.association(:fiction).target }
      return fictions.any?(&:licensed?) if fictions.all?

      Fiction.licensed.exists?(id: chapters.map(&:fiction_id).uniq)
    end
  end
end
