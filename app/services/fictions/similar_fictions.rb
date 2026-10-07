# frozen_string_literal: true

module Fictions
  # «Схожі твори»: other works ranked by shared genres, where a rare genre counts more than a common one.
  # The same team adds a little, a different age band takes some away (more the further apart the bands are),
  # and a licensed work sinks below equal matches without being hidden.
  # When too few works share a genre, the team's other works and then the most viewed works of the same age band
  # fill the row.
  class SimilarFictions
    LIMIT = 8
    TEAM_BONUS = 0.5
    # Indexed by how many bands apart (0+ / 16+ / 18+) the two works are.
    AGE_BAND_PENALTIES = [0.0, 0.5, 1.5].freeze
    LICENSED_PENALTY = 1.0
    CACHE_TTL = 24.hours
    GENRE_WEIGHTS_KEY = 'fiction-genre-weights/v1'

    def self.genre_weights
      Rails.cache.fetch(GENRE_WEIGHTS_KEY, expires_in: CACHE_TTL) do
        listed = Fiction.where.not(chapter_count: 0)
        total = listed.count
        FictionGenre.where(fiction_id: listed.select(:id)).group(:genre_id).count
                    .transform_values { |count| Math.log((total + 1).fdiv(count + 1)) }
      end
    end

    def initialize(fiction)
      @fiction = fiction
    end

    def fictions
      ids = Rails.cache.fetch("similar-to/v3/#{@fiction.id}", expires_in: CACHE_TTL) { ranked_ids }
      records = Fiction.where(id: ids).includes(:genres, :fiction_ratings, cover_attachment: :blob).index_by(&:id)
      ids.filter_map { |id| records[id] }
    end

    def ranked_ids
      ranked = scored_ids
      return ranked if ranked.size >= LIMIT

      (ranked + fallback_ids(ranked)).uniq.first(LIMIT)
    end

    private

    def pool = Fiction.where.not(id: @fiction.id).where.not(chapter_count: 0)

    def scored_ids
      scored_rows.select { |_id, score, _views| score.positive? }
                 .sort_by { |id, score, views| [-score, -views, id] }
                 .first(LIMIT).map(&:first)
    end

    def scored_rows
      scores = genre_scores
      return [] if scores.empty?

      pool.where(id: scores.keys).pluck(:id, :content_rating, :licensed_at, :views)
          .map { |id, band, licensed_at, views| [id, scores[id] + adjustment(id, band, licensed_at), views] }
    end

    def genre_scores
      weights = self.class.genre_weights
      shared = FictionGenre.where(genre_id: @fiction.fiction_genres.select(:genre_id), fiction_id: pool.select(:id))
      shared.pluck(:fiction_id, :genre_id).each_with_object(Hash.new(0.0)) do |(id, genre_id), scores|
        scores[id] += weights.fetch(genre_id, 0.0)
      end
    end

    def adjustment(id, band, licensed_at)
      (team_ids.include?(id) ? TEAM_BONUS : 0) - band_penalty(band) - (licensed_at ? LICENSED_PENALTY : 0)
    end

    def band_penalty(band)
      AGE_BAND_PENALTIES[(band_step(band) - band_step(@fiction.content_rating)).abs]
    end

    def band_step(band) = Fiction.content_ratings.keys.index(band)

    def team_ids
      @team_ids ||= FictionScanlator.where(scanlator_id: @fiction.fiction_scanlators.select(:scanlator_id))
                                    .distinct.pluck(:fiction_id).to_set
    end

    def fallback_ids(taken)
      rest = pool.where.not(id: taken).order(views: :desc, id: :asc).limit(LIMIT)
      rest.where(id: team_ids.to_a).pluck(:id) + rest.where(content_rating: @fiction.content_rating).pluck(:id)
    end
  end
end
