# frozen_string_literal: true

# A reader's thanks for one chapter. The reader can take it back; the chapter keeps the count.
class ChapterThank < ApplicationRecord
  belongs_to :user
  belongs_to :chapter, counter_cache: :thanks_count

  validates :user_id, uniqueness: { scope: :chapter_id }

  after_commit :invalidate_scanlator_stats, on: %i[create destroy]

  private

  # `chapter.scanlator_ids` is the form accessor, not the association's ids.
  def invalidate_scanlator_stats
    Scanlators::StatsCacheInvalidation.for_scanlator_ids(chapter.scanlators.ids)
  end
end
