# frozen_string_literal: true

class BookmarksAccounter
  include LibraryHelper

  attr_reader :fiction

  def initialize(fiction:)
    @fiction = fiction
  end

  def call
    return [0] unless last_chapter

    finished = finished_readings
    postponed = postponed_readings
    dropped = dropped_readings

    active = total_readings - (finished + postponed + dropped)

    [active, finished, postponed, dropped]
  end

  private

  def dropped_readings
    fiction.readings.where('updated_at < ?', latest_chapter_created_at - 2.months).count
  end

  def finished_readings
    latest_chapter_id = last_chapter.id
    fiction.readings.where(chapter_id: latest_chapter_id).count
  end

  def last_chapter
    @last_chapter ||= ordered_chapters_desc(fiction).first
  end

  def latest_chapter_created_at
    @latest_chapter_created_at ||= last_chapter.created_at
  end

  def postponed_readings
    fiction.readings.where(
      'updated_at < ? AND updated_at >= ?',
      latest_chapter_created_at - 1.month,
      latest_chapter_created_at - 2.months
    ).count
  end

  def total_readings
    fiction.readings.count
  end
end
