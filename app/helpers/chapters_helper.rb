# frozen_string_literal: true

module ChaptersHelper
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

  def volume_number_integer(number)
    return 'NA' if number.nil?

    number.zero? ? 0 : ((number || 0) * 100).to_i
  end

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
