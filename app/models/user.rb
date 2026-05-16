# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :confirmable

  devise :omniauthable, omniauth_providers: [:google_oauth2]

  validates :name, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  belongs_to :avatar
  belongs_to :latest_read_comment, class_name: 'Comment', optional: true
  has_many :comments
  has_many :publications
  has_many :readings, class_name: 'ReadingProgress', dependent: :destroy
  has_many :chat_messages, dependent: :destroy
  has_many :fiction_ratings, dependent: :destroy

  has_many :user_pokemons, dependent: :destroy
  has_many :pokemons, through: :user_pokemons
  has_many :attacker_battle_logs, class_name: 'PokemonBattleLog', foreign_key: :attacker_id
  has_many :defender_battle_logs, class_name: 'PokemonBattleLog', foreign_key: :defender_id

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

  def profile_show_assignments
    {
      recent_publications: profile_recent_publications,
      user_scanlators: scanlators,
      recent_comments: profile_recent_comments,
      recent_readings: profile_recent_readings,
      user_bookshelves: profile_featured_bookshelves
    }
  end

  def profile_recent_publications
    publications.includes(:cover_attachment, :rich_text_description).weekly.recent.limit(3)
  end

  def profile_recent_comments
    comments.order(created_at: :desc).includes(:commentable).limit(3)
  end

  def profile_recent_readings
    readings.includes(fiction: :cover_attachment, chapter: {}).order(updated_at: :desc).limit(4)
  end

  def profile_featured_bookshelves
    bookshelves.includes(fictions: [:cover_attachment]).most_viewed.limit(1)
  end

  def profile_pokemon_stats
    {
      pokemon_count: pokemons.count,
      total_pokemon: Pokemon.where(descendant_level: 0).count,
      victories: battle_victory_count,
      total_battles: battle_total_count,
      user_rating: dex_leader_rank
    }
  end

  def battle_victory_count
    attacker_battle_logs.where(winner: self).count +
      defender_battle_logs.where(winner: self).count
  end

  def battle_total_count
    attacker_battle_logs.count + defender_battle_logs.count
  end

  def dex_leader_rank
    self.class.dex_leaders.index(self) + 1
  end
end
