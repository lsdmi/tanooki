# frozen_string_literal: true

require_relative '../../config/initializers/telegram_bot'

class Publication < ApplicationRecord
  extend FriendlyId
  acts_as_paranoid
  friendly_id :slug_candidates
  searchkick callbacks: :async

  attr_accessor :tag_ids

  after_create :send_to_telegram

  belongs_to :user
  has_one_attached :cover
  has_rich_text :description
  has_many :comments
  has_many :publication_tags, dependent: :destroy
  has_many :tags, through: :publication_tags

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

  def send_to_telegram
    return unless Rails.env.production?

    TelegramBot.init
    url = "baka.in.ua/#{Rails.application.routes.url_helpers.tale_path(self)}"
    TelegramBot.bot.api.send_message(chat_id: '@bakaInUa', text: url)
  end
end
