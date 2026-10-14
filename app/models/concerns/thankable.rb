# frozen_string_literal: true

# Reader thanks on a chapter ({ChapterThank}). The count is the `thanks_count` counter cache.
module Thankable
  extend ActiveSupport::Concern

  included do
    # delete_all: soft-deleting many chapters must not load thanks one by one. Scanlator stats refresh once below;
    # a single thank still invalidates from ChapterThank's after_commit.
    has_many :chapter_thanks, dependent: :delete_all
    after_destroy :invalidate_scanlator_stats_for_thanks
  end

  def thanked_by?(user)
    return false unless user
    return chapter_thanks.any? { it.user_id == user.id } if chapter_thanks.loaded?

    chapter_thanks.exists?(user_id: user.id)
  end

  private

  def invalidate_scanlator_stats_for_thanks
    Scanlators::StatsCacheInvalidation.for_scanlator_ids(scanlators.ids)
  end
end
