# frozen_string_literal: true

module Fictions
  # After a fiction save: sync genre/scanlator links. Listing state is derived, not written.
  class SyncAssociationsAndStatus
    def initialize(fiction, genre_ids:, scanlator_ids:, user: nil)
      @fiction = fiction
      @genre_ids = genre_ids
      @scanlator_ids = scanlator_ids
      @user = user
    end

    def call
      SyncAssociations.new(@fiction, genre_ids: @genre_ids, scanlator_ids: @scanlator_ids, user: @user).call
    end
  end
end
