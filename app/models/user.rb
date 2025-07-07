# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  devise :omniauthable, omniauth_providers: [:google_oauth2]

  validates :name, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  belongs_to :avatar
  belongs_to :latest_read_comment, class_name: 'Comment', optional: true
  has_many :comments
  has_many :publications
  has_many :readings, class_name: 'ReadingProgress', dependent: :destroy
  has_many :chat_messages, dependent: :destroy

  has_many :user_pokemons, dependent: :destroy
  has_many :pokemons, through: :user_pokemons
  has_many :attacker_battle_logs, class_name: 'PokemonBattleLog', foreign_key: :attacker_id
  has_many :defender_battle_logs, class_name: 'PokemonBattleLog', foreign_key: :defender_id

  has_many :scanlator_users, dependent: :destroy
  has_many :scanlators, through: :scanlator_users
  has_many :chapters, through: :scanlators
  has_many :fictions, through: :scanlators

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

  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data[:email]).first

    user || User.create(
      avatar_id: Avatar.all.sample.id,
      confirmed_at: Time.now,
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
end
