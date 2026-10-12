# frozen_string_literal: true

module Reading
  # Three fictions with the newest reading activity, one row per fiction.
  class RecentRanobe
    LIMIT = 3

    def self.call
      new.call
    end

    def call
      ids = latest_fiction_ids
      by_id = Fiction.where(id: ids).index_by(&:id)
      ids.filter_map { |id| by_id[id] }
    end

    private

    def latest_fiction_ids
      ReadingProgress.joins(:fiction)
                     .group(:fiction_id)
                     .order(Arel.sql('MAX(reading_progresses.updated_at) DESC'))
                     .limit(LIMIT)
                     .pluck(:fiction_id)
    end
  end
end
