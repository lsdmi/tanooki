# frozen_string_literal: true

# A chapter the user finished reading. Sparse: completing chapter 6 never implies 4 or 5.
# Stores the exact translation read; translations sharing [volume_number, number] count as the same chapter.
class ReadingChapterRead < ApplicationRecord
  # scroll / next come from the reader; manual from the drawer toggle; legacy when a pre-rebuild snapshot is
  # turned into real reads (see Reading::RemoveRead).
  EVENT_SOURCES = %w[scroll next].freeze
  SOURCES = (EVENT_SOURCES + %w[manual legacy]).freeze

  belongs_to :user
  belongs_to :fiction
  belongs_to :chapter

  validates :completed_at, presence: true
  validates :source, inclusion: { in: SOURCES }
  validates :chapter_id, uniqueness: { scope: :user_id }

  def self.chapter_key(chapter)
    [chapter.volume_number, chapter.number]
  end

  # String join skips Chapter's soft-delete scope: a deleted translation was still read.
  def self.read_keys(user:, fiction:)
    where(user:, fiction:)
      .joins('INNER JOIN chapters ON chapters.id = reading_chapter_reads.chapter_id')
      .pluck('chapters.volume_number', 'chapters.number')
      .to_set
  end
end
