# frozen_string_literal: true

module Chapters
  # Chapter list accordion sections grouped by volume or number range.
  module ListSectionsHelper
    def chapters_collection(chapters)
      Library::ChapterCatalog.group_by_number_range(chapters)
    end

    # Builds accordion sections for the chapter list: numbered volumes first, then unnumbered chapters by range.
    # +order+ (:asc / :desc) reverses section order and chapter order within each section.
    def chapter_list_sections(chapters, order: :asc)
      descending = descending_order?(order)
      volume_sections = volume_chapter_sections(chapters, descending, order)
      unnumbered = chapters.where(volume_number: nil)
      return volume_sections unless unnumbered.exists?

      volume_sections + range_chapter_sections(range_source(chapters, unnumbered, volume_sections), descending, order)
    end

    def volume_section_key(volume_number) = "v-#{volume_number}"

    def range_section_key(range_label) = "r-#{range_label}"

    def fiction_chapter_section_path(fiction, section_key, order:)
      chapter_section_fiction_path(fiction, section: section_key, order: order)
    end

    def chapter_list_section_ids(section_chapters)
      section_chapters.pluck(:id)
    end

    def chapter_list_section_current?(section, current_chapter_id)
      return false if current_chapter_id.blank?

      section[:chapters].exists?(id: current_chapter_id)
    end

    private

    def range_sort_key(range_label)
      range_label.to_s.split('-').first.to_i
    end

    def descending_order?(order) = order.to_sym == :desc

    def volume_chapter_sections(chapters, descending, order)
      volume_numbers = chapter_volume_numbers(chapters)
      volume_numbers.reverse! if descending

      volume_numbers.map do |volume_number|
        volume_chapter_section(chapters, volume_number, order)
      end
    end

    def chapter_volume_numbers(chapters)
      # Drop inherited ORDER BY before DISTINCT/PLUCK (MySQL rejects ORDER BY columns outside SELECT with DISTINCT).
      chapters.unscope(:order).where.not(volume_number: nil).pluck(:volume_number).uniq.sort_by(&:to_f)
    end

    def volume_chapter_section(chapters, volume_number, order)
      {
        kind: :volume,
        section_key: volume_section_key(volume_number),
        volume_number: volume_number,
        title: "Том #{Formatting.format_decimal(volume_number)}",
        chapters: chapters.where(volume_number: volume_number).reorder(chapter_list_order_sql(order)),
        epub_title: "Том #{Formatting.format_decimal(volume_number)}"
      }
    end

    def range_source(chapters, unnumbered, volume_sections) = volume_sections.any? ? unnumbered : chapters

    def range_chapter_sections(chapters, descending, order)
      range_groups = chapters_collection(chapters).to_a.sort_by { |range, _| range_sort_key(range) }
      range_groups.reverse! if descending

      range_groups.map { |range, grouped| range_chapter_section(range, grouped, order) }
    end

    def range_chapter_section(range, grouped, order)
      {
        kind: :range,
        section_key: range_section_key(range),
        range: range,
        title: "Розділи #{range}",
        chapters: chapter_scope_for_group(grouped, order: order),
        epub_title: "Розділи #{range}"
      }
    end

    def chapter_scope_for_group(grouped, order:)
      ids = grouped.is_a?(ActiveRecord::Relation) ? grouped.pluck(:id) : grouped.map(&:id)
      return Chapter.none if ids.empty?

      Chapter.where(id: ids).reorder(chapter_list_order_sql(order))
    end

    def chapter_list_order_sql(order)
      if descending_order?(order)
        Library::ChapterCatalog.order_clause_desc
      else
        Library::ChapterCatalog.order_clause
      end
    end
  end
end
