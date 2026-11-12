# frozen_string_literal: true

# A reader's report of a translation error on one chapter reader block (data-rp-i + quote + digest).
class ParagraphReport < ApplicationRecord
  STATUSES = %w[open fixed dismissed].freeze
  QUOTE_MAX = 120
  MESSAGE_MAX = 500
  DIGEST_LENGTH = Chapters::ReaderBlocks::DIGEST_LENGTH

  belongs_to :user
  belongs_to :chapter
  belongs_to :resolved_by, class_name: 'User', optional: true, inverse_of: :resolved_paragraph_reports

  enum :status, STATUSES.index_by(&:to_sym), default: :open, validate: true

  validates :block_index, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quote, presence: true, length: { maximum: QUOTE_MAX }
  validates :digest, presence: true, length: { is: DIGEST_LENGTH }
  validates :message, length: { maximum: MESSAGE_MAX }, allow_nil: true

  scope :resolved, -> { where(status: %i[fixed dismissed]) }
  scope :for_scanlator_ids, lambda { |ids|
    joins(chapter: :scanlators).where(scanlators: { id: ids }).distinct
  }
end
