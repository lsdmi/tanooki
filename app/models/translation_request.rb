# frozen_string_literal: true

# Community request for a new translation project.
class TranslationRequest < ApplicationRecord
  belongs_to :user
  belongs_to :scanlator, optional: true
  has_many :translation_request_votes, dependent: :destroy

  validates :title, presence: true, length: { maximum: 150 }
  validates :notes, presence: true, length: { maximum: 500 }
  validates :source_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) },
            allow_blank: true

  scope :by_votes, -> { order(votes_count: :desc, created_at: :desc) }

  def user_voted?(user)
    return false unless user

    translation_request_votes.exists?(user: user)
  end

  def assigned?
    scanlator_id.present?
  end
end
