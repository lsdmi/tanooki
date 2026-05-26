# frozen_string_literal: true

# Persistent async EPUB export request with an attached generated file.
class EpubExportRequest < ApplicationRecord
  DOWNLOAD_TTL = 24.hours
  STATUS_LABELS = {
    'queued' => 'У черзі',
    'processing' => 'Готується',
    'ready' => 'Готово',
    'failed' => 'Помилка'
  }.freeze

  belongs_to :user, optional: true
  has_one_attached :file

  enum :status, { queued: 0, processing: 1, ready: 2, failed: 3 }

  before_validation :assign_token, on: :create
  before_validation :assign_expiry, on: :create

  validates :token, :status, :expires_at, presence: true
  validates :token, uniqueness: true
  validates :rich_text_ids, presence: true

  scope :expired, -> { where(expires_at: ..Time.current) }

  def downloadable?
    ready? && file.attached? && !expired?
  end

  def expired?
    expires_at <= Time.current
  end

  def status_label
    STATUS_LABELS.fetch(status)
  end

  private

  def assign_token
    self.token ||= SecureRandom.urlsafe_base64(24)
  end

  def assign_expiry
    self.expires_at ||= DOWNLOAD_TTL.from_now
  end
end
