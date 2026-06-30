# frozen_string_literal: true

module Chapters
  # Builds accordion section metadata for chapter lists without loading every chapter row.
  class ListSectionIndex
    RANGE_KEY_SQL = <<~SQL.squish
      CASE
        WHEN FLOOR(chapters.number) = 0 THEN '1-100'
        ELSE CONCAT(
          ((FLOOR(chapters.number) - 1) DIV 100) * 100 + 1,
          '-',
          ((FLOOR(chapters.number) - 1) DIV 100) * 100 + 100
        )
      END
    SQL

    CHAPTER_IDS_SQL = 'GROUP_CONCAT(chapters.id ORDER BY chapters.number, chapters.id)'

    def initialize(scope, order: :asc)
      @scope = scope
      @order = order
    end

    def call
      descending = @order.to_sym == :desc
      volume_sections = volume_section_rows(descending)
      unnumbered = base_scope.where(volume_number: nil)
      return volume_sections unless unnumbered.exists?

      volume_sections + range_section_rows(unnumbered, volume_sections.any?, descending)
    end

    private

    def base_scope
      @scope.unscope(:order)
    end

    def volume_section_rows(descending)
      rows = base_scope.where.not(volume_number: nil)
                       .group(:volume_number)
                       .pluck(:volume_number, Arel.sql(CHAPTER_IDS_SQL))

      rows.sort_by! { |volume_number, _| volume_number.to_f }
      rows.reverse! if descending

      rows.map { |volume_number, ids_concat| volume_metadata(volume_number, ids_concat) }
    end

    def range_section_rows(unnumbered_scope, volumes_exist, descending)
      source = volumes_exist ? unnumbered_scope : base_scope.where(volume_number: nil)
      rows = source.group(Arel.sql(RANGE_KEY_SQL))
                   .pluck(Arel.sql(RANGE_KEY_SQL), Arel.sql(CHAPTER_IDS_SQL))

      rows.sort_by! { |range, _| range_sort_key(range) }
      rows.reverse! if descending

      rows.map { |range, ids_concat| range_metadata(range, ids_concat) }
    end

    def volume_metadata(volume_number, ids_concat)
      formatted = Formatting.format_decimal(volume_number)
      title = "Том #{formatted}"

      {
        kind: :volume,
        section_key: ListSections.volume_section_key(volume_number),
        volume_number: volume_number,
        title: title,
        epub_title: title,
        chapter_ids: parse_ids(ids_concat)
      }
    end

    def range_metadata(range, ids_concat)
      title = "Розділи #{range}"

      {
        kind: :range,
        section_key: ListSections.range_section_key(range),
        range: range,
        title: title,
        epub_title: title,
        chapter_ids: parse_ids(ids_concat)
      }
    end

    def parse_ids(concat)
      concat.to_s.split(',').filter_map { |id| Integer(id, 10, exception: false) }
    end

    def range_sort_key(range_label)
      range_label.to_s.split('-').first.to_i
    end
  end
end
