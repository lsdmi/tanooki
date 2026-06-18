# frozen_string_literal: true

module WeeklyDigests
  # Query layer for the weekly stats Telegram digest.
  class Stats
    attr_reader :chapters_this_week_count, :top_chapter, :top_fiction, :featured_fiction

    def self.build(now: Time.zone.now)
      new(now:).gather
    end

    def initialize(now: Time.zone.now)
      @now = now
    end

    def gather
      @chapters_this_week_count = chapters_public_in(this_week_range).count
      @top_chapter = top_chapter_last_week
      @top_fiction = top_fiction_by_reading_activity_last_week
      @featured_fiction = random_fiction_with_new_chapter_last_week
      self
    end

    private

    attr_reader :now

    def chapters_public_in(range)
      Chapter.released.where("#{Chapter::PUBLIC_TIME_SQL} BETWEEN ? AND ?", range.begin, range.end)
    end

    def top_chapter_last_week
      chapters_public_in(last_week_range).order(views: :desc, id: :asc).first
    end

    def top_fiction_by_reading_activity_last_week
      counts = ReadingProgress.where(updated_at: last_week_range).group(:fiction_id).count
      return nil if counts.empty?

      fiction_id = counts.max_by { |fid, cnt| [cnt, -fid] }&.first
      Fiction.find_by(id: fiction_id)
    end

    def random_fiction_with_new_chapter_last_week
      Fiction.joins(:chapters).merge(chapters_public_in(last_week_range))
             .distinct.order(Arel.sql('RAND()')).first
    end

    def this_week_range
      now.all_week
    end

    def last_week_range
      1.week.ago(now).all_week
    end
  end
end
