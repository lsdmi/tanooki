# frozen_string_literal: true

class Publication < ApplicationRecord
  extend FriendlyId
  acts_as_paranoid
  friendly_id :slug_candidates
  searchkick callbacks: :async

  belongs_to :user
  has_one_attached :cover
  has_rich_text :description
  has_many :comments

  validates :title, :description, :cover, :status, :status_message, presence: true

  scope :highlights, -> { where(highlight: true) }
  scope :not_highlights, -> { where(highlight: false) }
  scope :last_month, -> { where(created_at: 1.month.ago..) }

  enum status: {
    created: 'created',
    approved: 'approved',
    declined: 'declined'
  }

  def search_data
    {
      title:,
      description: description.to_plain_text
    }
  end

  def slug_candidates
    [
      title.downcase
    ]
  end

  def should_index?
    approved?
  end
end
