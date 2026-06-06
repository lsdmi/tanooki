# frozen_string_literal: true

# User-curated list of fictions.
class Bookshelf < ApplicationRecord
  belongs_to :user
  has_many :bookshelf_fictions, dependent: :destroy
  has_many :fictions, through: :bookshelf_fictions

  delegate :name, :sqid, to: :user, prefix: true

  attr_accessor :fiction_ids

  validates :title, presence: true, length: { minimum: 3, maximum: 100, allow_blank: true }
  validates :description, presence: true, length: { minimum: 10, maximum: 500, allow_blank: true }
  validate :must_have_at_least_one_fiction

  after_save :assign_fictions

  scope :ordered, -> { order(:created_at) }
  scope :most_viewed, -> { order(views: :desc) }
  scope :by_sqid, lambda { |sqid_string|
    decoded = Sqids.new.decode(sqid_string.to_s)
    decoded.any? ? where(id: decoded.first) : none
  }

  def self.find_by_sqid(sqid_string)
    by_sqid(sqid_string).first
  end

  def sqid
    Sqids.new.encode([id])
  end

  def to_param
    sqid
  end

  private

  def must_have_at_least_one_fiction
    return unless fiction_ids.blank? || fiction_ids.compact_blank.empty?

    errors.add(:fiction_ids, 'Оберіть принаймні один твір')
  end

  def assign_fictions
    return if fiction_ids.blank?

    bookshelf_fictions.destroy_all

    fiction_ids.compact_blank.each do |fiction_id|
      bookshelf_fictions.create!(fiction_id: fiction_id)
    end
  end
end
