# frozen_string_literal: true

class Avatar < ApplicationRecord
  has_one_attached :image
  has_many :users, dependent: :nullify

  delegate_missing_to :image

  validates :image, presence: true
  validate :image_format

  after_destroy :reassign_avatars

  private

  def image_format
    return unless image.attached?
    return if image.content_type.in?(%w[image/jpeg image/png image/gif image/svg+xml image/webp])

    errors.add(:image, 'має бути JPEG, PNG, GIF, SVG, або WebP')
  end

  def reassign_avatars
    User.avatarless.each { |user| user.update(avatar: Avatar.all.sample) }
  end
end
