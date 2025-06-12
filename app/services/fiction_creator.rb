# frozen_string_literal: true

class FictionCreator
  def initialize(fiction, genre_ids:, scanlator_ids:)
    @fiction = fiction
    @genre_ids = genre_ids
    @scanlator_ids = scanlator_ids
  end

  def call
    FictionGenresManager.new(@genre_ids, @fiction).operate
    FictionScanlatorsManager.new(@scanlator_ids, @fiction).operate
  end
end
