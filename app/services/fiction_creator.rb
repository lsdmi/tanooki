# frozen_string_literal: true

# Syncs genre and scanlator associations when saving fiction.
class FictionCreator
  def initialize(fiction, genre_ids:, scanlator_ids:, user: nil)
    @fiction = fiction
    @genre_ids = genre_ids
    @scanlator_ids = scanlator_ids
    @user = user
  end

  def call
    FictionGenresManager.new(@genre_ids, @fiction).operate
    FictionScanlatorsManager.new(@scanlator_ids, @fiction, user: @user).operate
  end
end
