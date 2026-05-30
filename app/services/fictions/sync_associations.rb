# frozen_string_literal: true

module Fictions
  # Syncs genre and scanlator links after a fiction is created.
  class SyncAssociations
    def initialize(fiction, genre_ids:, scanlator_ids:, user: nil)
      @fiction = fiction
      @genre_ids = genre_ids
      @scanlator_ids = scanlator_ids
      @user = user
    end

    def call
      SyncGenres.new(genre_ids, fiction).call
      SyncScanlatorAssociations.new(scanlator_ids, fiction, user:).call
    end

    private

    attr_reader :fiction, :genre_ids, :scanlator_ids, :user
  end
end
