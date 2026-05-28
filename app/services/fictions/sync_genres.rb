# frozen_string_literal: true

module Fictions
  # Creates and removes genre links on a fiction from submitted genre_ids.
  class SyncGenres
    attr_reader :genre_ids, :fiction

    def initialize(genre_ids, fiction)
      @genre_ids = genre_ids
      @fiction = fiction
    end

    def call
      return if genre_ids.nil?

      create_fiction_genres
      destroy_fiction_genres
    end

    private

    def create_fiction_genres
      genres_to_add = submitted_genre_ids - existing_genre_ids
      genres_to_add.each { |genre_id| fiction.fiction_genres.create(genre_id:) }
    end

    def destroy_fiction_genres
      genres_to_remove = existing_genre_ids - submitted_genre_ids
      genres_to_remove.each { |genre_id| fiction.fiction_genres.find_by(genre_id:).destroy }
    end

    def existing_genre_ids
      fiction.genres.ids
    end

    def submitted_genre_ids
      genre_ids.reject(&:empty?).map(&:to_i)
    end
  end
end
