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

      current = existing_genre_ids
      submitted = submitted_genre_ids
      write_genre_links(current, submitted)
      # Search indexes genre_ids off the fiction row, so a genre edit has to save it or search stays stale.
      fiction.update!(updated_at: Time.current) if current.sort != submitted.sort
    end

    private

    def write_genre_links(current, submitted)
      (submitted - current).each { |genre_id| fiction.fiction_genres.create(genre_id:) }
      (current - submitted).each { |genre_id| fiction.fiction_genres.find_by(genre_id:).destroy }
    end

    def existing_genre_ids
      fiction.genres.ids
    end

    def submitted_genre_ids
      genre_ids.reject(&:empty?).map(&:to_i)
    end
  end
end
