# frozen_string_literal: true

module ChaptersHelper
  def chapter_epub_download_allowed?(chapter)
    chapter.scanlators.all?(&:convertable?)
  end

  def chapters_allow_epub_download?(chapters)
    list = Array(chapters)
    list.any? && list.all? { |ch| chapter_epub_download_allowed?(ch) }
  end

  def check_decimal(number)
    decimal_part = number.to_s.split('.').last.to_i
    decimal_part.zero? ? number.to_i : number
  end

  def chapters_collection(chapters)
    chapters.group_by do |chapter|
      if chapter.number.to_i.zero?
        '1-100'
      else
        range_start = (((chapter.number.to_i - 1) / 100) * 100) + 1
        range_end = range_start + 99
        "#{range_start}-#{range_end}"
      end
    end
  end

  # Builds accordion sections for the chapter list: numbered volumes first, then unnumbered chapters by range.
  # +order+ (:asc / :desc) reverses volume and range section order to match the chapter sort toggle.
  def chapter_list_sections(chapters, order: :asc)
    sections = []
    descending = order.to_sym == :desc

    # Drop inherited ORDER BY before DISTINCT/PLUCK (MySQL rejects ORDER BY columns outside SELECT with DISTINCT).
    volume_numbers = chapters.unscope(:order).where.not(volume_number: nil).pluck(:volume_number).uniq.sort_by(&:to_f)
    volume_numbers.reverse! if descending
    volume_numbers.each do |volume_number|
      sections << {
        kind: :volume,
        section_key: volume_section_key(volume_number),
        volume_number: volume_number,
        title: "Том #{check_decimal(volume_number)}",
        chapters: chapters.where(volume_number: volume_number),
        epub_title: "Том #{check_decimal(volume_number)}"
      }
    end

    unnumbered = chapters.where(volume_number: nil)
    return sections unless unnumbered.exists?

    range_source = sections.any? ? unnumbered : chapters
    range_groups = chapters_collection(range_source).to_a
    range_groups.sort_by! { |range, _| range_sort_key(range) }
    range_groups.reverse! if descending
    range_groups.each do |range, grouped|
      section_scope = grouped.is_a?(ActiveRecord::Relation) ? grouped : Chapter.where(id: grouped.map(&:id))
      sections << {
        kind: :range,
        section_key: range_section_key(range),
        range: range,
        title: "Розділи #{range}",
        chapters: section_scope,
        epub_title: "Розділи #{range}"
      }
    end

    sections
  end

  def range_sort_key(range_label)
    range_label.to_s.split('-').first.to_i
  end

  def volume_section_key(volume_number)
    "v-#{volume_number}"
  end

  def range_section_key(range_label)
    "r-#{range_label}"
  end

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

  private :range_sort_key

  def title_includes_rozdil?(title)
    return true if title.blank?

    title.match?(/Розділ/i)
  end

  # Half-hour slots 00:00–23:30 (24h labels). Includes +selected+ if it is not on the grid (legacy data).
  def chapter_publish_time_select_options(selected = nil)
    slots = (0..23).flat_map do |h|
      [0, 30].map { |m| format('%<hour>02d:%<minute>02d', hour: h, minute: m) }
    end
    options = slots.map { |t| [t, t] }
    options.unshift([selected, selected]) if selected.present? && slots.exclude?(selected)
    options
  end
end
