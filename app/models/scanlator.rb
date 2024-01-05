# frozen_string_literal: true

class Scanlator < ApplicationRecord
  extend FriendlyId

  friendly_id :slug_candidates

  has_one_attached :avatar
  has_one_attached :banner

  attr_accessor :member_ids

  before_destroy :check_associations

  has_many :chapter_scanlators, dependent: :destroy
  has_many :chapters, through: :chapter_scanlators

  has_many :fiction_scanlators, dependent: :destroy
  has_many :fictions, through: :fiction_scanlators

  has_many :scanlator_users, dependent: :destroy
  has_many :users, through: :scanlator_users

  before_validation :cleanup_member_ids

  validates :avatar, :banner, presence: true
  validates :description, length: { minimum: 3, maximum: 255 }, allow_blank: true
  validates :member_ids, presence: { message: 'мусить бути принаймні один учасник' }
  validates :title, length: { minimum: 3, maximum: 100 }
  validates :telegram_id, length: { minimum: 3, maximum: 50 }, allow_blank: true
  validate :avatar_format, :banner_format

  def avatar_format
    return unless avatar.attached?
    return if avatar.content_type.in?(%w[image/jpeg image/png image/svg+xml image/webp])

    errors.add(:avatar, 'має бути JPEG, PNG, SVG, або WebP')
  end

  def banner_format
    return unless banner.attached?
    return if banner.content_type.in?(%w[image/jpeg image/png image/svg+xml image/webp])

    errors.add(:banner, 'має бути JPEG, PNG, SVG, або WebP')
  end

  def slug_candidates
    [
      title&.downcase
    ]
  end

  private

  def check_associations
    return unless fictions.exists? || chapters.exists?

    errors.add(:base, 'Перш ніж видалити - приберіть всі пов\'язані з командою твори та розділи!')
    throw(:abort)
  end

  def cleanup_member_ids
    self.member_ids = member_ids&.reject(&:blank?)
  end
end
