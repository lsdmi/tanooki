# frozen_string_literal: true

class ReadingHistoryGrouper
  def initialize(readings, chapter_fetcher:)
    @readings = readings
    @chapter_fetcher = chapter_fetcher
  end

  def group
    groups = Hash.new { |h, k| h[k] = [] }

    @readings.each do |reading|
      group = group_for(reading)
      groups[group] << reading
    end

    groups
  end

  private

  def group_for(reading)
    fiction = reading.fiction
    last_chapter = @chapter_fetcher.call(fiction)
    latest_chapter_created_at = last_chapter.created_at

    return :finished   if finished?(reading, last_chapter)
    return :postponed  if postponed?(reading, latest_chapter_created_at)
    return :dropped    if dropped?(reading, latest_chapter_created_at)

    :active
  end

  def finished?(reading, last_chapter)
    reading.chapter_id == last_chapter.id
  end

  def postponed?(reading, latest_chapter_created_at)
    reading.updated_at < (latest_chapter_created_at - 1.month) &&
      reading.updated_at >= (latest_chapter_created_at - 2.months)
  end

  def dropped?(reading, latest_chapter_created_at)
    reading.updated_at < (latest_chapter_created_at - 2.months)
  end
end
