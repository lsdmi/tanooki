# frozen_string_literal: true

# Timed writing contest with submissions, judging, and awards.
class Contest < ApplicationRecord
  include NormalizesWhitespace

  extend FriendlyId

  KINDS = %w[original fanfiction translation art].freeze
  JUDGED_CHAPTERS_SCOPES = %w[until_close in_window].freeze

  DEFAULT_CRITERIA = [
    { 'key' => 'idea', 'label' => 'Ідея та оригінальність', 'weight' => 25 },
    { 'key' => 'style', 'label' => 'Мова і стиль', 'weight' => 25 },
    { 'key' => 'characters', 'label' => 'Персонажі', 'weight' => 20 },
    { 'key' => 'world', 'label' => 'Світ і атмосфера', 'weight' => 15 },
    { 'key' => 'hook', 'label' => 'Захопливість', 'weight' => 15 }
  ].freeze

  normalizes_squished :title, :tagline, :teaser_text, :cancel_reason

  friendly_id :slug_candidates

  has_rich_text :description
  has_rich_text :rules

  has_one_attached :cover
  has_one_attached :banner
  has_one_attached :entry_placeholder_cover

  belongs_to :required_genre, class_name: 'Genre', optional: true
  belongs_to :source_contest, class_name: 'Contest', optional: true

  has_many :prizes, class_name: 'ContestPrize', dependent: :destroy, inverse_of: :contest
  has_many :entries, class_name: 'ContestEntry', dependent: :destroy, inverse_of: :contest
  has_many :awards, class_name: 'ContestAward', dependent: :destroy, inverse_of: :contest
  has_many :jurors, class_name: 'ContestJuror', dependent: :destroy, inverse_of: :contest
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :exclusive_avatars, class_name: 'Avatar', dependent: :nullify, inverse_of: :contest

  accepts_nested_attributes_for :prizes, allow_destroy: true,
                                         reject_if: ->(attrs) { attrs['title'].blank? }
  accepts_nested_attributes_for :jurors, allow_destroy: true,
                                         reject_if: ->(attrs) { attrs['user_id'].blank? }

  attribute :rule_changes, :json, default: -> { [] }
  attribute :criteria, :json, default: -> { DEFAULT_CRITERIA.map(&:dup) }
  attribute :sponsors, :json, default: -> { [] }
  attribute :announcements_sent, :json, default: -> { [] }

  enum :kind, KINDS.index_by(&:to_sym), validate: true
  enum :judged_chapters_scope, JUDGED_CHAPTERS_SCOPES.index_by(&:to_sym),
       validate: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :tagline, :teaser_text, length: { maximum: 160 }, allow_blank: true
  validates :announced_at, :submissions_open_at, :submissions_close_at, :judging_close_at, presence: true
  validates :jury_weight, numericality: { only_integer: true, in: 0..100 }
  validates :max_content_rating, inclusion: { in: Fiction.content_ratings.values }
  validates :max_entries_per_user, numericality: { only_integer: true, greater_than: 0 }
  validates :min_chapters,
            numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :prize_pool_uah, :donations_uah, :carryover_uah,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :dates_strictly_increasing
  validate :criteria_weights_sum_to_hundred

  include ContestAttachmentFormats

  # Not draft: published and announced_at has arrived (cancelled/results still listed).
  scope :visible, lambda {
    now = Time.current
    where.not(published_at: nil).where(published_at: ..now).where(announced_at: ..now)
  }
  # Announced through awaiting_results.
  scope :active, -> { visible.where(cancelled_at: nil, results_published_at: nil) }
  scope :archived, lambda {
    visible.where.not(results_published_at: nil).or(visible.where.not(cancelled_at: nil))
  }

  def phase(at: Time.current)
    Contests::Phase.new(self, at:).call
  end

  def draft?(at: Time.current) = phase(at:) == :draft
  def submissions_open?(at: Time.current) = phase(at:) == :submissions
  def results_published? = results_published_at.present?
  def cancelled? = cancelled_at.present?

  # Accepted (and locked) entries still waiting for admin reject/DQ after the deadline.
  def unreviewed_after_deadline?(at: Time.current)
    return false if submissions_close_at.blank? || submissions_close_at > at

    entries.exists?(reviewed_at: nil, status: %w[accepted qualified incomplete])
  end

  def slug_candidates
    [title.to_s.downcase]
  end

  def should_generate_new_friendly_id?
    slug.blank? || (title_changed? && title.present?)
  end

  private

  def dates_strictly_increasing
    return if [announced_at, submissions_open_at, submissions_close_at, judging_close_at].any?(&:blank?)
    return if announced_at < submissions_open_at &&
              submissions_open_at < submissions_close_at &&
              submissions_close_at < judging_close_at

    errors.add(:base, :dates_not_increasing)
  end

  def criteria_weights_sum_to_hundred
    list = Array(criteria)
    return errors.add(:criteria, :blank) if list.blank?

    total = list.sum { |row| row.is_a?(Hash) ? row['weight'].to_i : 0 }
    return if total == 100

    errors.add(:criteria, :weights_must_sum_to_hundred)
  end
end
