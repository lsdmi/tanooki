# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  devise :omniauthable, omniauth_providers: [:google_oauth2]

  validates :name, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  belongs_to :avatar
  has_many :chapters
  has_many :comments
  has_many :publications
  has_many :readings, class_name: 'ReadingProgress', dependent: :destroy
  has_many :user_fictions, dependent: :destroy
  has_many :fictions, through: :user_fictions

  has_many :user_pokemons, dependent: :destroy
  has_many :pokemons, through: :user_pokemons
  has_many :attacker_battle_logs, class_name: 'PokemonBattleLog', foreign_key: :attacker_id
  has_many :defender_battle_logs, class_name: 'PokemonBattleLog', foreign_key: :defender_id

  scope :admins, -> { where(admin: true) }
  scope :avatarless, -> { where(avatar_id: nil) }

  scope :dex_leaders, lambda {
    joins(:user_pokemons)
      .includes([{ avatar: { image_attachment: :blob } }, :attacker_battle_logs, :defender_battle_logs])
      .group(:user_id)
      .order(battle_win_rate: :desc)
  }

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
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

  def battle_logs_includes_details
    attacker_battle_logs.includes([:rich_text_details, :attacker, :defender, :winner]) +
    defender_battle_logs.includes([:rich_text_details, :attacker, :defender, :winner])
  end
end
