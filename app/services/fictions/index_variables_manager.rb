# frozen_string_literal: true

module Fictions
  class IndexVariablesManager
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

    def self.popular_novelty_ids_for_badges
      Fiction.joins(:readings)
             .group(:id)
             .where(id: Fiction.last(15).pluck(:id))
             .order('COUNT(reading_progresses.fiction_id) DESC')
             .limit(8)
             .pluck(:id)
             .to_set
    end

    def self.most_reads
      Rails.cache.fetch('most_reads', expires_in: 24.hours) do
        Fiction.includes(%i[cover_attachment genres fiction_ratings]).most_reads.limit(6)
      end
    end

    def self.most_reads_ids_for_badges
      Fiction.most_reads.limit(6).pluck(:id).to_set
    end

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
      Rails.cache.fetch('hot_updates', expires_in: 12.hours) do
        Fiction.joins(:readings)
               .includes({ cover_attachment: :blob })
               .group(:id)
               .where(readings: { created_at: 1.month.ago..Time.now })
               .order('COUNT(readings.fiction_id) DESC')
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
