# frozen_string_literal: true

# Join model linking chapters to scanlator teams.
class ChapterScanlator < ApplicationRecord
  belongs_to :chapter
  belongs_to :scanlator

  after_commit :invalidate_scanlator_stats_cache, on: %i[create destroy]

  private

  def invalidate_scanlator_stats_cache
    Scanlators::StatsCacheInvalidation.for_scanlator_ids(scanlator_id)
  end
end
