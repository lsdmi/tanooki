# frozen_string_literal: true

module Fictions
  # «Перейти до розділу»: finds the chapter by number in the visible list and the window of rows around it inside
  # its group, in the list's current order. Translations share a number; the first row in that order wins.
  # With `chapter_id` (the «До поточного розділу» chip) it finds that exact row instead.
  class ChapterJump
    WINDOW = 20
    ROWS_ABOVE_TARGET = 9

    Result = Data.define(:error, :number, :section, :rows, :window_start, :target_index) do
      def found? = error.nil?

      def window = rows.slice(window_start, WINDOW)

      def rows_above = rows.first(window_start)
    end

    # sections: Chapters::ListSectionIndex output for `order`; section_rows: section → its chapters in that order.
    def initialize(listed:, sections:, query:, section_rows:, chapter_id: nil)
      @listed = listed
      @sections = sections
      @query = query
      @section_rows = section_rows
      @chapter_id = chapter_id
    end

    def call
      return find_chapter if @chapter_id

      number = parse(@query)
      return failure(:invalid) unless number

      section = section_for(number)
      return failure(:missing, number) unless section

      found(section, number) { |row| row.number == number }
    end

    def self.parse(query)
      text = query.to_s.delete('#').strip.tr(',', '.')
      return unless text.match?(/\A\d+(\.\d+)?\z/)

      BigDecimal(text)
    end

    private

    def parse(query) = self.class.parse(query)

    # Volumes that restart numbering repeat a number; the group shown first in the current order wins.
    def section_for(number)
      keys = @listed.filter_map do |chapter|
        Chapters::ListSectionIndex.section_key_for(chapter) if chapter.number == number
      end
      @sections.find { |section| keys.include?(section[:section_key]) }
    end

    def find_chapter
      chapter = @listed.find { |listed| listed.id == @chapter_id }
      return failure(:gone) unless chapter

      key = Chapters::ListSectionIndex.section_key_for(chapter)
      section = @sections.find { |candidate| candidate[:section_key] == key }
      found(section, chapter.number) { |row| row.id == chapter.id }
    end

    def found(section, number, &)
      rows = @section_rows.call(section)
      index = rows.index(&)
      return failure(:missing, number) unless index

      start = (index - ROWS_ABOVE_TARGET).clamp(0, [rows.size - WINDOW, 0].max)
      Result.new(error: nil, number:, section:, rows:, window_start: start, target_index: index - start)
    end

    def failure(error, number = nil)
      Result.new(error:, number:, section: nil, rows: [], window_start: 0, target_index: nil)
    end
  end
end
