# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  devise :omniauthable, omniauth_providers: [:google_oauth2]

  validates :name, presence: true, length: { minimum: 3, maximum: 20 }
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

  scope :admins, -> { where(admin: true) }
  scope :avatarless, -> { where(avatar_id: nil) }

  scope :dex_leaders, lambda {
    joins(:user_pokemons)
      .includes(avatar: { image_attachment: :blob })
      .select('users.*, COUNT(DISTINCT user_pokemons.pokemon_id) AS unique_pokemon_count')
      .group(:user_id)
      .order('unique_pokemon_count DESC')
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
end
