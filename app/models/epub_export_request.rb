# frozen_string_literal: true

require 'digest'

# Persistent async EPUB export request with an attached generated file.
class EpubExportRequest < ApplicationRecord
  include EpubExportRequestJobStatusSync

  DOWNLOAD_TTL = 24.hours
  STALE_PROCESSING_AFTER = 30.minutes
  STATUS_LABELS = {
    'queued' => 'У черзі',
    'processing' => 'Готується',
    'ready' => 'Готово',
    'failed' => 'Помилка'
  }.freeze

  belongs_to :user
  has_one_attached :file

  enum :status, { queued: 0, processing: 1, ready: 2, failed: 3 }

  before_validation :assign_token, on: :create
  before_validation :assign_expiry, on: :create
  before_validation :normalize_export_content, on: :create

  validates :token, :status, :expires_at, :content_fingerprint, presence: true
  validates :token, uniqueness: true
  validates :rich_text_ids, presence: true

  scope :expired, -> { where(expires_at: ..Time.current) }
  scope :active, -> { where(expires_at: Time.current..) }

  def self.find_reusable_for(user:, rich_text_ids:, volume_title: nil)
    fingerprint = content_fingerprint(rich_text_ids, volume_title)
    export = user.epub_export_requests
                 .active
                 .where(content_fingerprint: fingerprint, status: %i[queued processing ready])
                 .order(created_at: :desc)
                 .first
    return nil unless export

    refreshed_for_reuse(export)
  end

  def self.refreshed_for_reuse(export)
    export.fail_if_stale_processing!
    export.sync_with_job_status!
    export if export.reusable_for_serve?
  end

  def self.content_fingerprint(rich_text_ids, volume_title = nil)
    ids = Array(rich_text_ids).map(&:to_i).sort.uniq.join(',')
    title = volume_title.to_s.presence || ''
    Digest::SHA256.hexdigest("#{ids}|#{title}")
  end

  def self.reject_if_too_large!(rich_text_ids)
    return unless Books::EpubExportLimits.too_large?(rich_text_ids)

    raise ArgumentError, I18n.t('downloads.epub_export.too_large')
  end

  def downloadable?
    ready? && file.attached? && !expired?
  end

  def expired?
    expires_at <= Time.current
  end

  def status_label
    STATUS_LABELS.fetch(status)
  end

  def reusable_for_serve?
    return false if failed? || expired?

    queued? || processing? || downloadable?
  end

  def stale_processing?
    processing? && updated_at < STALE_PROCESSING_AFTER.ago
  end

  def fail_if_stale_processing!
    return unless stale_processing?

    update!(
      status: :failed,
      error_message: I18n.t('downloads.epub_export.generation_interrupted')
    )
  end

  private

  def assign_token
    self.token ||= SecureRandom.urlsafe_base64(24)
  end

  def assign_expiry
    self.expires_at ||= DOWNLOAD_TTL.from_now
  end

  def normalize_export_content
    self.rich_text_ids = Array(rich_text_ids).map(&:to_i).sort.uniq
    self.volume_title = volume_title.presence
    self.content_fingerprint = self.class.content_fingerprint(rich_text_ids, volume_title)
  end
end
