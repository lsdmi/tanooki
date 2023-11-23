# frozen_string_literal: true

class FictionRanker
  attr_reader :fiction

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
    Fiction.joins(:genres)
          .left_joins(:readings)
          .group('fictions.id')
          .where(genres: { id: genre.id })
          .order('COUNT(reading_progresses.fiction_id) DESC')
          .index(fiction) + 1
  end
end
