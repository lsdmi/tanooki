# frozen_string_literal: true

# Registered site member (reader, author, or admin).
class User < ApplicationRecord
  include NormalizesWhitespace
  include UserProfile

  # Moved to trainer_profiles; dropped in a later deploy.
  self.ignored_columns += %w[battle_win_rate pokemon_last_catch pokemon_last_training pinned_opponent_id pinned_until
                             opponent_rerolled_at]

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes_squished :name

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

  has_one :trainer_profile, dependent: :delete
  has_many :user_pokemons, dependent: :destroy
  has_many :pokemons, through: :user_pokemons
  has_many :pokemon_encounters, dependent: :delete_all

  has_many :scanlator_users, dependent: :destroy
  has_many :scanlators, through: :scanlator_users
  has_many :chapters, through: :scanlators
  has_many :fictions, through: :scanlators
  has_many :bookshelves, dependent: :destroy
  has_many :translation_requests, dependent: :destroy
  has_many :translation_request_votes, dependent: :destroy

  scope :avatarless, -> { where(avatar_id: nil) }

  after_create :trainer_profile

  def send_devise_notification(notification, *)
    devise_mailer.send(notification, self, *).deliver_later
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

  # Created on first use when missing (accounts made while the backfill deployed); the unique index settles a race.
  def trainer_profile
    super || (self.trainer_profile = TrainerProfile.create_or_find_by!(user: self))
  end

  def latest_battle
    PokemonBattle.involving(self)
                 .includes(:winner, attacker: { avatar: :image_attachment }, defender: { avatar: :image_attachment })
                 .order(created_at: :desc, id: :desc).first
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
end
