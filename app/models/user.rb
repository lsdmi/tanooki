# frozen_string_literal: true

# Registered site member (reader, author, or admin).
class User < ApplicationRecord
  include UserProfile

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :confirmable

  devise :omniauthable, omniauth_providers: [:google_oauth2]

  validates :name, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  belongs_to :avatar
  belongs_to :latest_read_comment, class_name: 'Comment', inverse_of: :users, optional: true
  has_many :comments, dependent: :destroy
  has_many :epub_export_requests, dependent: :destroy
  has_many :publications, dependent: :destroy
  has_many :readings, class_name: 'ReadingProgress', dependent: :destroy
  has_many :chat_messages, dependent: :destroy
  has_many :fiction_ratings, dependent: :destroy

  has_many :user_pokemons, dependent: :destroy
  has_many :pokemons, through: :user_pokemons
  has_many :attacker_battle_logs, class_name: 'PokemonBattleLog', foreign_key: :attacker_id,
                                  inverse_of: :attacker, dependent: :nullify
  has_many :defender_battle_logs, class_name: 'PokemonBattleLog', foreign_key: :defender_id,
                                  inverse_of: :defender, dependent: :nullify

  has_many :scanlator_users, dependent: :destroy
  has_many :scanlators, through: :scanlator_users
  has_many :chapters, through: :scanlators
  has_many :fictions, through: :scanlators
  has_many :bookshelves, dependent: :destroy
  has_many :translation_requests, dependent: :destroy
  has_many :translation_request_votes, dependent: :destroy

  scope :avatarless, -> { where(avatar_id: nil) }

  scope :dex_leaders, lambda {
    joins(:user_pokemons)
      .includes(avatar: :image_attachment)
      .group(:user_id)
      .order(battle_win_rate: :desc)
  }

  def send_devise_notification(notification, *)
    devise_mailer.send(notification, self, *).deliver_later
  end

  # Future Premium / No-Ads tier: return true when the member should not see AdSense or the reader ad drawer.
  def ads_free?
    false
  end

  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data[:email]).first

    user || User.create(
      avatar_id: Avatar.all.sample.id,
      confirmed_at: Time.zone.now,
      email: data[:email],
      name: data[:name][0, 20],
      password: Devise.friendly_token[0, 20]
    )
  end

  def battle_logs
    attacker_battle_logs + defender_battle_logs
  end

  def latest_battle_log
    logs = PokemonBattleLog
           .includes(:rich_text_details, :attacker, :defender, :winner)
           .where('attacker_id = :user_id OR defender_id = :user_id', user_id: id)
           .order(created_at: :desc)
    logs.first
  end

  def self.find_by_sqid(sqid_string)
    ids = Sqids.new.decode(sqid_string)
    find_by(id: ids.first) if ids.any?
  end

  def manages_chapter?(chapter)
    admin? || chapters.exists?(id: chapter.id)
  end

  def manages_fiction?(fiction)
    admin? || fictions.exists?(id: fiction.id)
  end

  def adult_content_acknowledged?
    adult_content_acknowledged_at.present?
  end

  def sqid
    Sqids.new.encode([id])
  end

  def chat_avatar_url
    return unless avatar&.image&.attached?

    avatar.image.url
  end

  def pokemon_catch_permitted?
    pokemon_last_catch < 4.hours.ago
  end

  def pokemon_training_on_cooldown?
    pokemon_last_training > 4.hours.ago
  end
end
