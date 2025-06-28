# frozen_string_literal: true

class ReadingProgress < ApplicationRecord
  belongs_to :chapter
  belongs_to :fiction
  belongs_to :user

  enum status: {
    active: 0,
    finished: 1,
    postponed: 2,
    dropped: 3
  }

  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :user_id, uniqueness: { scope: :fiction_id, message: 'already has reading progress for this fiction' }

  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(updated_at: :desc) }

  def fiction_description
    fiction.description
  end

  def fiction_title
    fiction.title
  end
end
