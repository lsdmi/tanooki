# frozen_string_literal: true

class Bookshelf < ApplicationRecord
  belongs_to :user
  has_many :bookshelf_fictions, dependent: :destroy
  has_many :fictions, through: :bookshelf_fictions

  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 500 }

  scope :ordered, -> { order(:created_at) }
  scope :by_user, ->(user) { where(user: user) }
  scope :most_viewed, -> { order(views: :desc) }

  def add_fiction(fiction)
    return false if fictions.include?(fiction)

    bookshelf_fictions.create!(fiction: fiction)
  end

  def remove_fiction(fiction)
    bookshelf_fictions.find_by(fiction: fiction)&.destroy
  end

  def self.find_by_sqid(sqid_string)
    ids = Sqids.new.decode(sqid_string)
    find_by(id: ids.first) if ids.any?
  end

  def sqid
    Sqids.new.encode([id])
  end
end
