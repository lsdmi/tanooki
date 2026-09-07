# frozen_string_literal: true

# Listing-progress columns: live chapter_count vs optional expected_chapters.
module FictionListingProgress
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_expected_chapters

    validates :chapter_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :expected_chapters, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
    validate :expected_chapters_at_least_chapter_count, if: :will_save_change_to_expected_chapters?
  end

  private

  def normalize_expected_chapters
    return if expected_chapters.nil?

    self.expected_chapters = nil if expected_chapters.to_i.zero?
  end

  def expected_chapters_at_least_chapter_count
    return if expected_chapters.nil?
    return if expected_chapters >= chapter_count

    errors.add(:expected_chapters, :greater_than_or_equal_to, count: chapter_count)
  end
end
