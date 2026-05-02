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
      Fiction.includes(%i[cover_attachment genres fiction_ratings]).most_reads.limit(6)
    end
  end

  def self.latest_updates
    Fiction
      .joins(:chapters)
      .merge(Chapter.released)
      .includes(%i[cover_attachment genres])
      .select("fictions.*, MAX(#{Chapter::PUBLIC_TIME_SQL}) AS max_created_at")
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

  # Cache only ids: marshalled Fiction rows lose preloads and trigger N+1 on banner/blob.
  def self.showcase
    ids = Rails.cache.fetch('fiction_showcase_ids', expires_in: 12.hours) { random_showcase_fiction_ids }
    return Fiction.none if ids.blank?

    showcase_fictions_for(ids)
  end

  def self.showcase_ids
    (latest_updates.map(&:id) + most_reads.pluck(:id) + popular_novelty.pluck(:id)).uniq
  end

  def self.random_showcase_fiction_ids
    Fiction
      .where(id: showcase_ids)
      .where.not(short_description: [nil, ''])
      .joins(:banner_attachment)
      .distinct
      .pluck(:id)
      .sample(5)
  end
  private_class_method :random_showcase_fiction_ids

  def self.showcase_fictions_for(ids)
    Fiction
      .where(id: ids)
      .includes(:fiction_ratings, banner_attachment: :blob)
      .in_order_of(:id, ids)
  end
  private_class_method :showcase_fictions_for
end
