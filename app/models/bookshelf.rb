# frozen_string_literal: true

class Bookshelf < ApplicationRecord
  belongs_to :user
  has_many :bookshelf_fictions, dependent: :destroy
  has_many :fictions, through: :bookshelf_fictions

  delegate :name, to: :user, prefix: true

  attr_accessor :fiction_ids

  validates :title, presence: true, length: { minimum: 3, maximum: 100, allow_blank: true }
  validates :description, presence: true, length: { minimum: 10, maximum: 500, allow_blank: true }
  validate :must_have_at_least_one_fiction

  after_save :assign_fictions

  scope :ordered, -> { order(:created_at) }
  scope :by_user, ->(user) { where(user: user) }
  scope :most_viewed, -> { order(views: :desc) }

  def self.find_by_sqid(sqid_string)
    ids = Sqids.new.decode(sqid_string)
    find_by(id: ids.first) if ids.any?
  end

  def sqid
    Sqids.new.encode([id])
  end

  private

  def must_have_at_least_one_fiction
    return unless fiction_ids.blank? || fiction_ids.reject(&:blank?).empty?

    errors.add(:fiction_ids, 'Оберіть принаймні один твір')
  end

  def assign_fictions
    return unless fiction_ids.present?

    bookshelf_fictions.destroy_all

    fiction_ids.reject(&:blank?).each do |fiction_id|
      bookshelf_fictions.create!(fiction_id: fiction_id)
    end
  end
end
