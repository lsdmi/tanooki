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

  def new_chapter?(list, chapter_id)
    return :black if list.nil?

    list.pluck(:id).include?(chapter_id) ? :green : :black
  end

  def volume_number_integer(number)
    return 'NA' if number.nil?

    number.zero? ? 0 : ((number || 0) * 100).to_i
  end
end
