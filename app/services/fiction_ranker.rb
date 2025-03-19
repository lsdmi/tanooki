# frozen_string_literal: true

class FictionRanker
  attr_reader :fiction

  RANK_OUT_OF_SCOPE = 11

  def initialize(fiction:)
    @fiction = fiction
  end

  def call
    fiction.genres.each_with_object({}) do |genre, genre_index_hash|
      index = calculate_genre_index(genre)
      genre_index_hash[genre.name] = index if index <= 10
    end
  end

  private

  def calculate_genre_index(genre)
    index = Fiction.joins(:genres).where(genres: { id: genre.id }).most_reads.index(fiction)

    index.nil? ? RANK_OUT_OF_SCOPE : index + 1
  end
end
