# frozen_string_literal: true

class FictionIndexVariablesManager
  def self.popular_novelty
    Rails.cache.fetch('popular_novelty', expires_in: 24.hours) do
      Fiction.joins(:readings)
             .includes(%i[cover_attachment])
             .group(:id)
             .where(id: Fiction.last(15).pluck(:id))
             .order('COUNT(reading_progresses.fiction_id) DESC')
             .limit(8)
    end
  end

  def self.most_reads
    Rails.cache.fetch('most_reads', expires_in: 24.hours) do
      Fiction.includes(%i[cover_attachment genres]).most_reads.limit(7)
    end
  end

  def self.latest_updates
    Fiction
      .joins(:chapters)
      .includes(%i[cover_attachment genres])
      .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
      .group('fictions.id')
      .order('max_created_at DESC')
      .limit(9)
  end

  def self.hot_updates
    Rails.cache.fetch('hot_updates', expires_in: 12.hours) do
      Fiction.joins(:readings)
             .includes({ cover_attachment: :blob })
             .group(:id)
             .where(readings: { created_at: 1.month.ago..Time.now })
             .order('COUNT(readings.fiction_id) DESC')
    end
  end
end
