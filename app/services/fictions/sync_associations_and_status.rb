# frozen_string_literal: true

module Fictions
  # After a fiction save: sync genre/scanlator links, then recompute status.
  class SyncAssociationsAndStatus
    def initialize(fiction, genre_ids:, scanlator_ids:, user: nil)
      @fiction = fiction
      @genre_ids = genre_ids
      @scanlator_ids = scanlator_ids
      @user = user
    end

    def call
      FictionCreator.new(@fiction, genre_ids: @genre_ids, scanlator_ids: @scanlator_ids, user: @user).call
      refresh_status
    end

    private

    def refresh_status
      new_status = DeriveStatusFromChapters.new(@fiction).call
      @fiction.update!(status: new_status)
    end
  end
end
