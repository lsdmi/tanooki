# frozen_string_literal: true

module Fictions
  class Ranker
    attr_reader :fiction

    RANK_OUT_OF_SCOPE = 11

    def initialize(fiction:)
      @fiction = fiction
    end

    def call
      fiction.genres.reject { |genre| genre.name == 'Конкурс' }.each_with_object({}) do |genre, genre_index_hash|
        index = calculate_genre_index(genre)
        genre_index_hash[genre.name] = index if index <= 10
      end
    end

    def self.most_read_fiction_ids_for_genre(genre, limit: 8)
      most_reads_relation_for_genre(genre).limit(limit).pluck(:id)
    end

    def self.most_read_fictions_for_genre(genre, limit: 8)
      ranked_ids = most_read_fiction_ids_for_genre(genre, limit: limit)
      return [] if ranked_ids.blank?

      Fiction
        .where(id: ranked_ids)
        .includes(:cover_attachment, :fiction_ratings)
        .in_order_of(:id, ranked_ids)
        .to_a
    end

    def self.most_reads_relation_for_genre(genre)
      Fiction
        .joins(:genres)
        .where(genres: { id: genre.id })
        .merge(Fiction.most_reads)
    end

    private

    def calculate_genre_index(genre)
      index = Ranker.most_reads_relation_for_genre(genre).index(fiction)

      index.nil? ? RANK_OUT_OF_SCOPE : index + 1
    end
  end
end
