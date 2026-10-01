# frozen_string_literal: true

module Chapters
  # Accordion section metadata for a fiction's chapter list: volumes first, then numeric ranges of unnumbered
  # chapters. Groups loaded chapters in memory (the request's shared list), so it never queries.
  class ListSectionIndex
    RANGE_SIZE = 100

    def self.volume_section_key(volume_number) = "v-#{volume_number}"

    def self.range_section_key(range_label) = "r-#{range_label}"

    # Chapters below 1 (prologues, 0.5) belong to the first range.
    def self.range_label(number)
      start = ([number.to_i, 1].max - 1) / RANGE_SIZE * RANGE_SIZE
      "#{start + 1}-#{start + RANGE_SIZE}"
    end

    def initialize(chapters, order: :asc)
      @chapters = chapters.to_a
      @descending = order.to_sym == :desc
    end

    def call
      with_volume, without_volume = @chapters.partition(&:volume_number)
      volume_sections(with_volume) + range_sections(without_volume)
    end

    private

    def volume_sections(chapters)
      groups = chapters.group_by(&:volume_number).sort_by { |volume_number, _| volume_number.to_f }
      in_list_order(groups).map do |volume_number, grouped|
        title = "Том #{Formatting.format_decimal(volume_number)}"
        section(:volume, self.class.volume_section_key(volume_number), title, grouped, volume_number:)
      end
    end

    def range_sections(chapters)
      groups = chapters.group_by { |chapter| self.class.range_label(chapter.number) }
                       .sort_by { |range, _| range.to_i }
      in_list_order(groups).map do |range, grouped|
        section(:range, self.class.range_section_key(range), "Розділи #{range}", grouped, range:)
      end
    end

    def in_list_order(groups)
      @descending ? groups.reverse : groups
    end

    def section(kind, section_key, title, chapters, **extra)
      {
        kind:,
        section_key:,
        **extra,
        title:,
        epub_title: title,
        chapter_ids: chapters.sort_by { |chapter| [chapter.number, chapter.id] }.map(&:id)
      }
    end
  end
end
