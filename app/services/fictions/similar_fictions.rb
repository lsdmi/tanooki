# frozen_string_literal: true

module Fictions
  # «Схожі твори»: other works ranked by shared genres and active tags, where a rare one counts more than a common
  # one and a tag counts half as much as a genre.
  # The same team adds a little, a different age band takes some away (more the further apart the bands are),
  # and a licensed work sinks below equal matches without being hidden.
  # When too few works share a genre or tag, the team's other works and then the most viewed works of the same
  # age band fill the row.
  class SimilarFictions
    LIMIT = 8
    TAG_WEIGHT = 0.5
    TEAM_BONUS = 0.5
    # Indexed by how many bands apart (0+ / 16+ / 18+) the two works are.
    AGE_BAND_PENALTIES = [0.0, 0.5, 1.5].freeze
    LICENSED_PENALTY = 1.0
    CACHE_TTL = 24.hours
    WEIGHTS_KEY = 'fiction-taxonomy-weights/v2'

    def self.weights
      Rails.cache.fetch(WEIGHTS_KEY, expires_in: CACHE_TTL) do
        listed = Fiction.where.not(chapter_count: 0).select(:id)
        total = listed.count
        { genres: rarity(FictionGenre.where(fiction_id: listed).group(:genre_id).count, total),
          tags: rarity(active_tag_links.where(fiction_id: listed).group(:fiction_tag_id).count, total) }
      end
    end

    def self.rarity(counts, total) = counts.transform_values { |count| Math.log((total + 1).fdiv(count + 1)) }

    def self.active_tag_links = FictionTagLink.where(fiction_tag_id: FictionTag.active.select(:id))

    def initialize(fiction, filter: ContentFilters::Preference.open)
      @fiction = fiction
      @filter = filter
      @hidden_count = 0
    end

    attr_reader :hidden_count

    # Ranked ids stay in one shared cache. The filter runs when those ids are loaded.
    def fictions
      ids = Rails.cache.fetch("similar-to/v5/#{@fiction.id}", expires_in: CACHE_TTL) { ranked_ids }
      visible = @filter.apply(Fiction.where(id: ids))
      records = visible.includes(:genres, :fiction_ratings, cover_attachment: :blob).index_by(&:id)
      ordered = ids.filter_map { |id| records[id] }
      @hidden_count = @filter.dropped_from(ids, ordered.map(&:id))
      ordered.first(LIMIT)
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
      scores = taxonomy_scores
      return [] if scores.empty?

      pool.where(id: scores.keys).pluck(:id, :content_rating, :licensed_at, :views)
          .map { |id, band, licensed_at, views| [id, scores[id] + adjustment(id, band, licensed_at), views] }
    end

    def taxonomy_scores
      weights = self.class.weights
      scores = Hash.new(0.0)
      add_scores(scores, shared_genres, weights[:genres])
      add_scores(scores, shared_tags, weights[:tags], TAG_WEIGHT)
      scores
    end

    def add_scores(scores, pairs, weights, factor = 1.0)
      pairs.each { |id, key| scores[id] += factor * weights.fetch(key, 0.0) }
    end

    def shared_genres
      FictionGenre.where(genre_id: @fiction.fiction_genres.select(:genre_id), fiction_id: pool.select(:id))
                  .pluck(:fiction_id, :genre_id)
    end

    def shared_tags
      FictionTagLink.where(fiction_tag_id: @fiction.fiction_tags.active.select(:id), fiction_id: pool.select(:id))
                    .pluck(:fiction_id, :fiction_tag_id)
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
