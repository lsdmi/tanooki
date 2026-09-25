# frozen_string_literal: true

# Tracks a user's reading status and position within a fiction.
class ReadingProgress < ApplicationRecord
  belongs_to :chapter
  belongs_to :fiction
  belongs_to :user

  has_many :chapter_reads, class_name: 'ReadingChapterRead',
                           foreign_key: %i[user_id fiction_id],
                           primary_key: %i[user_id fiction_id],
                           inverse_of: false,
                           dependent: nil

  enum :status, { active: 0, finished: 1, postponed: 2, dropped: 3 }

  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :user_id, uniqueness: { scope: :fiction_id }

  scope :recent, -> { order(updated_at: :desc) }

  delegate :description, :title, to: :fiction, prefix: true
end
