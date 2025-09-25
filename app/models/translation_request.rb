# frozen_string_literal: true

class TranslationRequest < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :scanlator, optional: true
  has_many :translation_request_votes, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { maximum: 150 }
  validates :notes, presence: true, length: { maximum: 500 }
  validates :user_id, presence: true
  validates :source_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: 'повинно бути дійсним URL' }, allow_blank: true

  # Scopes
  scope :by_creation_date, -> { order(created_at: :desc) }
  scope :by_votes, -> { order(votes_count: :desc, created_at: :desc) }

  # Helper methods for voting
  def upvote_count
    translation_request_votes.count
  end

  def user_voted?(user)
    return false unless user

    translation_request_votes.exists?(user: user)
  end
end
