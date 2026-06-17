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

  def active_recently?
    Stats.compute(self).active_recently?
  end

  def average_rating
    Stats.compute(self).average_rating
  end

  def total_rating_count
    Stats.compute(self).total_rating_count
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
