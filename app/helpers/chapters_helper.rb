# frozen_string_literal: true

# Chapter view helpers: grouping, navigation ids, EPUB availability, and publish-time options.
module ChaptersHelper
  HALF_HOUR_MINUTES = [0, 30].freeze

  def chapter_epub_download_allowed?(chapter)
    Books::EpubDownloadPermission.allowed?([chapter])
  end

  def chapters_allow_epub_download?(chapters)
    Books::EpubDownloadPermission.allowed?(chapters)
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
    descending = descending_order?(order)
    volume_sections = volume_chapter_sections(chapters, descending)
    unnumbered = chapters.where(volume_number: nil)
    return volume_sections unless unnumbered.exists?

    volume_sections + range_chapter_sections(range_source(chapters, unnumbered, volume_sections), descending)
  end

  def range_sort_key(range_label)
    range_label.to_s.split('-').first.to_i
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

  private :range_sort_key

  def descending_order?(order) = order.to_sym == :desc

  def volume_chapter_sections(chapters, descending)
    volume_numbers = chapter_volume_numbers(chapters)
    volume_numbers.reverse! if descending

    volume_numbers.map do |volume_number|
      volume_chapter_section(chapters, volume_number)
    end
  end

  def chapter_volume_numbers(chapters)
    # Drop inherited ORDER BY before DISTINCT/PLUCK (MySQL rejects ORDER BY columns outside SELECT with DISTINCT).
    chapters.unscope(:order).where.not(volume_number: nil).pluck(:volume_number).uniq.sort_by(&:to_f)
  end

  def volume_chapter_section(chapters, volume_number)
    {
      kind: :volume,
      section_key: volume_section_key(volume_number),
      volume_number: volume_number,
      title: "Том #{check_decimal(volume_number)}",
      chapters: chapters.where(volume_number: volume_number),
      epub_title: "Том #{check_decimal(volume_number)}"
    }
  end

  def range_source(chapters, unnumbered, volume_sections) = volume_sections.any? ? unnumbered : chapters

  def range_chapter_sections(chapters, descending)
    range_groups = chapters_collection(chapters).to_a.sort_by { |range, _| range_sort_key(range) }
    range_groups.reverse! if descending

    range_groups.map { |range, grouped| range_chapter_section(range, grouped) }
  end

  def range_chapter_section(range, grouped)
    {
      kind: :range,
      section_key: range_section_key(range),
      range: range,
      title: "Розділи #{range}",
      chapters: chapter_scope_for_group(grouped),
      epub_title: "Розділи #{range}"
    }
  end

  def chapter_scope_for_group(grouped)
    return grouped if grouped.is_a?(ActiveRecord::Relation)

    Chapter.where(id: grouped.map(&:id))
  end

  def title_includes_rozdil?(title)
    return true if title.blank?

    title.match?(/Розділ/i)
  end

  # Half-hour slots 00:00–23:30 (24h labels). Includes +selected+ if it is not on the grid (legacy data).
  def chapter_publish_time_select_options(selected = nil)
    slots = (0..23).flat_map do |h|
      HALF_HOUR_MINUTES.map { |m| format('%<hour>02d:%<minute>02d', hour: h, minute: m) }
    end
    options = slots.map { |t| [t, t] }
    options.unshift([selected, selected]) if selected.present? && slots.exclude?(selected)
    options
  end
end
