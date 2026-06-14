# frozen_string_literal: true

module Chapters
  # Builds accordion sections for the chapter list: volumes first, then unnumbered ranges.
  class ListSections
    def initialize(chapters, order: :asc)
      @chapters = chapters
      @order = order
    end

    def call
      descending = descending_order?
      volume_sections = volume_chapter_sections(descending)
      unnumbered = @chapters.where(volume_number: nil)
      return volume_sections unless unnumbered.exists?

      volume_sections + range_chapter_sections(range_source(unnumbered, volume_sections), descending)
    end

    def self.volume_section_key(volume_number) = "v-#{volume_number}"

    def self.range_section_key(range_label) = "r-#{range_label}"

    private

    def descending_order? = @order.to_sym == :desc

    def volume_chapter_sections(descending)
      volume_numbers = chapter_volume_numbers
      volume_numbers.reverse! if descending

      volume_numbers.map { |volume_number| volume_chapter_section(volume_number) }
    end

    def chapter_volume_numbers
      @chapters.unscope(:order).where.not(volume_number: nil).pluck(:volume_number).uniq.sort_by(&:to_f)
    end

    def volume_chapter_section(volume_number)
      {
        kind: :volume,
        section_key: self.class.volume_section_key(volume_number),
        volume_number: volume_number,
        title: "Том #{Formatting.format_decimal(volume_number)}",
        chapters: @chapters.where(volume_number: volume_number).reorder(chapter_list_order_sql),
        epub_title: "Том #{Formatting.format_decimal(volume_number)}"
      }
    end

    def range_source(unnumbered, volume_sections)
      volume_sections.any? ? unnumbered : @chapters
    end

    def range_chapter_sections(chapters, descending)
      range_groups = Library::ChapterCatalog.group_by_number_range(chapters)
                                            .to_a
                                            .sort_by { |range, _| range_sort_key(range) }
      range_groups.reverse! if descending

      range_groups.map { |range, grouped| range_chapter_section(range, grouped) }
    end

    def range_chapter_section(range, grouped)
      {
        kind: :range,
        section_key: self.class.range_section_key(range),
        range: range,
        title: "Розділи #{range}",
        chapters: chapter_scope_for_group(grouped),
        epub_title: "Розділи #{range}"
      }
    end

    def range_sort_key(range_label)
      range_label.to_s.split('-').first.to_i
    end

    def chapter_scope_for_group(grouped)
      ids = grouped.is_a?(ActiveRecord::Relation) ? grouped.pluck(:id) : grouped.map(&:id)
      return Chapter.none if ids.empty?

      Chapter.where(id: ids).reorder(chapter_list_order_sql)
    end

    def chapter_list_order_sql
      if descending_order?
        Library::ChapterCatalog.order_clause_desc
      else
        Library::ChapterCatalog.order_clause
      end
    end
  end
end
