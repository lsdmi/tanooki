# frozen_string_literal: true

# Official Ukrainian license, an overlay on top of the derived listing progress. It never changes
# `listing_state` or `completed_at`; it only replaces the public status label.
module FictionLicense
  extend ActiveSupport::Concern

  HTTPS_URL = /\A#{URI::DEFAULT_PARSER.make_regexp(%w[https])}\z/
  # The team may undo its own mark for this long; after that only an admin can clear it.
  LICENSE_GRACE_PERIOD = 24.hours

  included do
    normalizes :license_publisher, :license_url, with: ->(value) { value.squish.presence }

    scope :licensed, -> { where.not(licensed_at: nil) }
    scope :not_licensed, -> { where(licensed_at: nil) }

    validates :license_publisher, length: { maximum: 100 }
    validates :license_url, length: { maximum: 500 }, format: { with: HTTPS_URL, allow_nil: true }
    validate :license_source_present, if: :licensed?

    # Chapter.released is wall-clock, so a schedule left in place would go live after the license.
    after_save :revert_scheduled_chapters, if: :license_just_marked?
  end

  def licensed?
    licensed_at.present?
  end

  def license_grace?
    marked_at = licensed_at_in_database
    marked_at.present? && marked_at > LICENSE_GRACE_PERIOD.ago
  end

  def license_clearable_by?(user)
    return false unless user

    user.admin? || (license_grace? && user.manages_fiction?(self))
  end

  def public_listing_label
    licensed? ? I18n.t('fictions.license.label') : listing_state_label
  end

  def public_listing_label_short
    licensed? ? I18n.t('fictions.license.label_short') : listing_state_label_short
  end

  private

  def license_source_present
    return if license_publisher || license_url

    errors.add(:license_publisher, :source_missing)
  end

  def license_just_marked?
    saved_change_to_licensed_at? && licensed_at_before_last_save.nil?
  end

  def revert_scheduled_chapters
    scheduled = chapters.published.where(published_at: Time.current..)
    return unless scheduled.exists?

    scheduled.find_each { |chapter| chapter.update!(status: :draft, published_at: nil) }
    Catalog::RefreshChapterStats.call(self)
  end
end
