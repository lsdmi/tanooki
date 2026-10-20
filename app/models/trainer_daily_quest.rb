# frozen_string_literal: true

# One of a trainer's three daily quests for a Kiev calendar day.
class TrainerDailyQuest < ApplicationRecord
  belongs_to :user

  validates :quest_on, :quest_key, :target, presence: true
  validates :quest_key, uniqueness: { scope: %i[user_id quest_on] }
  validates :progress, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :target, numericality: { only_integer: true, greater_than: 0 }

  scope :for_day, ->(user, on) { where(user:, quest_on: on).order(:id) }

  def completed?
    completed_at.present?
  end
end
