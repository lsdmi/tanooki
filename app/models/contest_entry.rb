# frozen_string_literal: true

# A fiction (or legacy archive row) submitted to a contest.
class ContestEntry < ApplicationRecord
  include NormalizesWhitespace

  STATUSES = %w[accepted rejected withdrawn qualified incomplete disqualified].freeze
  AI_USAGES = %w[none assist substantial].freeze
  ACTIVE_STATUSES = %w[accepted qualified incomplete disqualified].freeze

  normalizes_squished :legacy_title, :legacy_author, :status_reason
  normalizes_stripped :legacy_url, :ai_note, :jury_review, :jury_private_review

  belongs_to :contest, inverse_of: :entries
  belongs_to :fiction, optional: true
  belongs_to :submitter, class_name: 'User', optional: true, inverse_of: :submitted_contest_entries
  belongs_to :scanlator, optional: true
  belongs_to :reviewed_by, class_name: 'User', optional: true

  has_many :entry_authors, class_name: 'ContestEntryAuthor', dependent: :destroy, inverse_of: :contest_entry
  has_many :authors, through: :entry_authors, source: :user
  has_many :awards, class_name: 'ContestAward', dependent: :destroy, inverse_of: :contest_entry

  enum :status, STATUSES.index_by(&:to_sym), validate: true
  enum :ai_usage, AI_USAGES.index_by(&:to_sym), prefix: :ai, validate: true

  validates :submitted_at, presence: true
  validates :fiction_id, uniqueness: { scope: :contest_id }, allow_nil: true
  validate :fiction_or_legacy_present
  validate :legacy_only_on_past_results

  scope :active, -> { where(status: ACTIVE_STATUSES) }
  scope :gallery, -> { where(status: %w[accepted qualified]) }

  def legacy? = fiction_id.blank?
  def display_title = fiction&.title.presence || legacy_title
  def display_author = fiction&.author.presence || legacy_author

  private

  def fiction_or_legacy_present
    return if fiction_id.present? || legacy_title.present?

    errors.add(:base, :fiction_or_legacy_required)
  end

  def legacy_only_on_past_results
    return if legacy_title.blank?
    return if contest&.results_published_at.present? && contest.results_published_at <= Time.current

    errors.add(:legacy_title, :only_for_past_results)
  end
end
