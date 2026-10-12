# frozen_string_literal: true

# Reader thanks on a chapter ({ChapterThank}). The count is the `thanks_count` counter cache.
module Thankable
  extend ActiveSupport::Concern

  included do
    has_many :chapter_thanks, dependent: :destroy
  end

  def thanked_by?(user)
    return false unless user
    return chapter_thanks.any? { it.user_id == user.id } if chapter_thanks.loaded?

    chapter_thanks.exists?(user_id: user.id)
  end
end
