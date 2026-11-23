# frozen_string_literal: true

module Fictions
  # Syncs genre, scanlator and tag links after a fiction is saved. Returns the tag sync result,
  # the only step that can reject input after the fiction row is written.
  class SyncAssociations
    def initialize(fiction, genre_ids:, scanlator_ids:, user: nil, tag_names: nil)
      @fiction = fiction
      @genre_ids = genre_ids
      @scanlator_ids = scanlator_ids
      @user = user
      @tag_names = tag_names
    end

    def call
      SyncGenres.new(genre_ids, fiction).call
      SyncScanlatorAssociations.new(scanlator_ids, fiction, user:).call
      FictionTags::Sync.call(fiction, names: tag_names)
    end

    private

    attr_reader :fiction, :genre_ids, :scanlator_ids, :user, :tag_names
  end
end
