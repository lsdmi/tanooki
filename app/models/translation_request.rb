# frozen_string_literal: true

class TranslationRequest < ApplicationRecord
  belongs_to :user
  belongs_to :scanlator, optional: true

  validates :title, presence: true, length: { in: 3..100 }
  validates :author, length: { maximum: 100 }, allow_blank: true
  validates :source_url, format: { with: URI::DEFAULT_PARSER.make_regexp }, allow_blank: true
  validates :notes, length: { maximum: 2000 }, allow_blank: true
  validates :votes_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
