# frozen_string_literal: true

class FictionUpdater
  def initialize(fiction, genre_ids:, scanlator_ids:)
    @fiction = fiction
    @genre_ids = genre_ids
    @scanlator_ids = scanlator_ids
  end

  def call
    FictionCreator.new(@fiction, genre_ids: @genre_ids, scanlator_ids: @scanlator_ids).call
    update_fiction_status
  end

  private

  def update_fiction_status
    new_status = FictionStatusTracker.new(@fiction).call
    @fiction.update_column(:status, new_status)
  end
end
