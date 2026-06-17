# frozen_string_literal: true

module Scanlators
  # Aggregated scanlator show-page stats (chapters, views, activity, ratings).
  class Stats
    ACTIVE_WINDOW = 60.days

    attr_reader :chapters_count, :total_views, :average_rating, :total_rating_count

    def initialize(chapters_count:, total_views:, active_recently:, average_rating:, total_rating_count:)
      @chapters_count = chapters_count
      @total_views = total_views
      @active_recently = active_recently
      @average_rating = average_rating
      @total_rating_count = total_rating_count
    end

    def active_recently?
      @active_recently
    end

    def to_h
      {
        chapters_count: chapters_count,
        total_views: total_views,
        active_recently: active_recently?,
        average_rating: average_rating,
        total_rating_count: total_rating_count
      }
    end

    def self.from_h(hash)
      new(
        chapters_count: hash[:chapters_count],
        total_views: hash[:total_views],
        active_recently: hash.fetch(:active_recently) { hash[:active_this_month] },
        average_rating: hash[:average_rating],
        total_rating_count: hash[:total_rating_count]
      )
    end

    def self.compute(scanlator)
      chapters = scanlator.chapters
      fiction_ids = scanlator.fiction_ids

      new(
        chapters_count: chapters.count,
        total_views: chapters.sum(:views),
        active_recently: active_recently?(chapters),
        **rating_stats(fiction_ids)
      )
    end

    def self.active_recently?(chapters)
      chapters.exists?(
        ["#{Chapter::PUBLIC_TIME_SQL} BETWEEN ? AND ?", ACTIVE_WINDOW.ago, Time.current]
      )
    end

    def self.rating_stats(fiction_ids)
      return { average_rating: 0.0, total_rating_count: 0 } if fiction_ids.empty?

      ratings = FictionRating.where(fiction_id: fiction_ids)
      {
        average_rating: average_rating_for(ratings),
        total_rating_count: ratings.count
      }
    end

    def self.average_rating_for(ratings)
      average = ratings.average(:rating)
      average ? average.round(1) : 0.0
    end
    private_class_method :active_recently?, :rating_stats, :average_rating_for
  end
end
