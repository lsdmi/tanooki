# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email, with: ->(e) { e.strip.downcase }

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

  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_initialize do |user|
      user.email = auth.info.email
      user.name = auth.info.name[0, 20] || auth.info.email.split('@').first[0, 20]
      user.password = SecureRandom.hex(16)
      user.email_verified_at = Time.current if auth.info.email_verified
      user.avatar_id ||= Avatar.all.sample.id
    end.tap(&:save!)
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
