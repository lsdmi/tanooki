# frozen_string_literal: true

# Updates fiction associations and recomputed publication status.
class FictionUpdater
  def initialize(fiction, genre_ids:, scanlator_ids:, user: nil)
    @fiction = fiction
    @genre_ids = genre_ids
    @scanlator_ids = scanlator_ids
    @user = user
  end

  def call
    FictionCreator.new(@fiction, genre_ids: @genre_ids, scanlator_ids: @scanlator_ids, user: @user).call
    update_fiction_status
  end

  private

  def update_fiction_status
    new_status = FictionStatusTracker.new(@fiction).call
    @fiction.update!(status: new_status)
  end
end
