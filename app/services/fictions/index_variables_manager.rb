# frozen_string_literal: true

module Fictions
  # Cached fiction lists and badge ids for the fictions index.
  class IndexVariablesManager
    def self.popular_novelty
      ids = cached_popular_novelty_ids
      return Fiction.none if ids.blank?

      Fiction.where(id: ids)
             .includes(%i[cover_attachment])
             .in_order_of(:id, ids)
    end

    def self.popular_novelty_ids_for_badges
      popular_novelty_scope.pluck(:id).to_set
    end

    def self.popular_novelty_scope
      Fiction.joins(:readings)
             .includes(%i[cover_attachment])
             .group(:id)
             .where(id: recent_fiction_ids)
             .order('COUNT(reading_progresses.fiction_id) DESC')
             .limit(8)
    end
    def self.cached_popular_novelty_ids
      Rails.cache.fetch('popular_novelty_ids', expires_in: 24.hours) do
        popular_novelty_scope.to_a.map(&:id)
      end
    end
    private_class_method :cached_popular_novelty_ids

    private_class_method :popular_novelty_scope

    def self.recent_fiction_ids
      Fiction.order(id: :desc).limit(15).pluck(:id)
    end
    private_class_method :recent_fiction_ids

    def self.most_reads
      ids = cached_most_reads_ids
      return Fiction.none if ids.blank?

      Fiction.where(id: ids)
             .includes(%i[cover_attachment genres fiction_ratings])
             .in_order_of(:id, ids)
    end

    def self.most_reads_ids_for_badges
      most_reads_scope.pluck(:id).to_set
    end

    def self.most_reads_scope
      Fiction.includes(%i[cover_attachment genres fiction_ratings]).most_reads.limit(6)
    end
    def self.cached_most_reads_ids
      Rails.cache.fetch('most_reads_ids', expires_in: 24.hours) do
        most_reads_scope.to_a.map(&:id)
      end
    end
    private_class_method :cached_most_reads_ids

    private_class_method :most_reads_scope

    def self.latest_updates_ranked
      Fiction
        .joins(:chapters)
        .merge(Chapter.released)
        .group('fictions.id')
        .order(Arel.sql("MAX(#{Chapter::PUBLIC_TIME_SQL}) DESC"))
        .limit(9)
    end
    private_class_method :latest_updates_ranked

    def self.latest_updates
      latest_updates_ranked
        .includes(%i[cover_attachment genres])
        .select("fictions.*, MAX(#{Chapter::PUBLIC_TIME_SQL}) AS max_created_at")
    end

    def self.latest_updates_ids_for_badges
      latest_updates_ranked.pluck(:id).to_set
    end

    def self.genre_recent_updates_excluding(genre, exclude_ids: [])
      base = Fiction.joins(:genres, :chapters).where(genres: { id: genre.id }).merge(Chapter.released)
      base = base.where.not(id: exclude_ids) if exclude_ids.present?
      ranked = base.select("fictions.id, MAX(#{Chapter::PUBLIC_TIME_SQL}) AS genre_sort_at").group('fictions.id')
      Fiction.includes(:cover_attachment, :fiction_ratings)
             .joins("INNER JOIN (#{ranked.to_sql}) AS genre_recent_agg ON genre_recent_agg.id = fictions.id")
             .order(Arel.sql('genre_recent_agg.genre_sort_at DESC'))
    end

    def self.hot_updates
      ids = cached_hot_updates_ids
      return Fiction.none if ids.blank?

      Fiction.where(id: ids)
             .includes({ cover_attachment: :blob })
             .in_order_of(:id, ids)
    end

    def self.cached_hot_updates_ids
      Rails.cache.fetch('hot_updates_ids', expires_in: 12.hours) do
        hot_updates_ranked_scope.to_a.map(&:id)
      end
    end
    private_class_method :cached_hot_updates_ids

    def self.hot_updates_ranked_scope
      Fiction.joins(:readings)
             .group(:id)
             .where(readings: { created_at: 1.month.ago..Time.zone.now })
             .order(Arel.sql('COUNT(readings.fiction_id) DESC'))
    end
    private_class_method :hot_updates_ranked_scope

    def self.hot_updates_counts
      Rails.cache.fetch('hot_updates_counts', expires_in: 12.hours) do
        ReadingProgress.where(created_at: 1.month.ago..Time.zone.now)
                       .group(:fiction_id)
                       .count
      end
    end

    def self.showcase
      IndexShowcase.for_index
    end

    def self.showcase_for_genre(genre)
      IndexShowcase.for_genre(genre)
    end
  end
end
