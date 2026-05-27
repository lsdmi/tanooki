# frozen_string_literal: true

# Translation team (scanlator group) publishing fictions and chapters.
class Scanlator < ApplicationRecord
  extend FriendlyId

  friendly_id :slug_candidates

  has_one_attached :avatar
  has_one_attached :banner

  attr_accessor :member_ids

  before_validation :cleanup_member_ids
  before_destroy :check_associations

  has_many :chapter_scanlators, dependent: :destroy
  has_many :chapters, through: :chapter_scanlators

  has_many :fiction_scanlators, dependent: :destroy
  has_many :fictions, through: :fiction_scanlators

  has_many :scanlator_users, dependent: :destroy
  has_many :users, through: :scanlator_users

  validates :avatar, :banner, presence: true
  validates :description, length: { minimum: 3, maximum: 255 }, allow_blank: true
  validates :notice, length: { minimum: 3, maximum: 255 }, allow_blank: true
  validates :member_ids, presence: true
  validates :title, length: { minimum: 3, maximum: 100 }
  validates :telegram_id, length: { minimum: 3, maximum: 50 }, allow_blank: true
  validate :avatar_format, :banner_format

  def avatar_format
    return unless avatar.attached?
    return if avatar.content_type.in?(%w[image/jpeg image/png image/svg+xml image/webp])

    errors.add(:avatar, :invalid_format)
  end

  def banner_format
    return unless banner.attached?
    return if banner.content_type.in?(%w[image/jpeg image/png image/svg+xml image/webp])

    errors.add(:banner, :invalid_format)
  end

  def slug_candidates
    [
      title&.downcase
    ]
  end

  def active_this_month?
    chapters.exists?(["#{Chapter::PUBLIC_TIME_SQL} BETWEEN ? AND ?", 60.days.ago, Time.current])
  end

  def average_rating
    return 0.0 if fictions.empty?

    # Calculate average rating across all fictions
    total_ratings = FictionRating.where(fiction_id: fiction_ids)
    return 0.0 if total_ratings.empty?

    total_ratings.average(:rating).round(1)
  end

  def total_rating_count
    return 0 if fictions.empty?

    fiction_ids = fictions.pluck(:id)
    FictionRating.where(fiction_id: fiction_ids).count
  end

  private

  def check_associations
    return unless fictions.exists? || chapters.exists?

    errors.add(:base, 'Перш ніж видалити - приберіть всі пов\'язані з командою твори та розділи!')
    throw(:abort)
  end

  def cleanup_member_ids
    self.member_ids =
      if member_ids.nil? && persisted? && users.exists?
        users.ids
      else
        member_ids&.compact_blank
      end
  end
end
