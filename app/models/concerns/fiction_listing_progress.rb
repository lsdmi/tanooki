# frozen_string_literal: true

# Listing-progress columns: live chapter_count vs optional editor-only expected_chapters.
# Badge is derived from stored facts — nothing writes a status.
module FictionListingProgress
  extend ActiveSupport::Concern

  STALE_AFTER = 90.days

  LISTING_STATE_LABELS = {
    finished: 'Завершено',
    stale: 'Покинуто',
    announced: 'Анонсовано',
    ongoing: 'Видається'
  }.freeze

  included do
    before_validation :normalize_expected_chapters

    validates :chapter_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :expected_chapters, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
    validate :expected_chapters_at_least_chapter_count, if: :will_save_change_to_expected_chapters?

    # Named listing_* so they do not clobber Fiction.statuses enum scopes until phase 9.
    scope :listing_finished, -> { where.not(completed_at: nil) }
    scope :listing_live, lambda {
      where(completed_at: nil).where.not(chapter_count: 0).where(last_chapter_at: STALE_AFTER.ago..)
    }
    scope :listing_announced, lambda {
      table = arel_table
      where(completed_at: nil).where(table[:chapter_count].eq(0).or(table[:last_chapter_at].eq(nil)))
    }
    scope :listing_stale, lambda {
      where(completed_at: nil)
        .where.not(chapter_count: 0)
        .where(arel_table[:last_chapter_at].lt(STALE_AFTER.ago))
    }
  end

  def listing_state
    return :finished if completed_at
    return :announced if chapter_count.zero? || last_chapter_at.blank?
    return :stale if last_chapter_at < STALE_AFTER.ago

    :ongoing
  end

  def listing_state_label
    LISTING_STATE_LABELS.fetch(listing_state)
  end

  def listing_state_label_short
    label = listing_state_label
    label.length > 6 ? "#{label[0, 6]}." : label
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
