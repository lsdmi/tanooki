# frozen_string_literal: true

# A wild Pokémon the server rolled for a signed-in user or a guest. Belongs to exactly one of the two.
class PokemonEncounter < ApplicationRecord
  EXPIRES_IN = 30.minutes
  SOURCES = %w[browse reading event].freeze
  CATCH_PURPOSE = :catch

  belongs_to :user, optional: true
  belongs_to :pokemon

  enum :status, { open: 'open', caught: 'caught', fled: 'fled', expired: 'expired' }, default: :open, validate: true

  scope :claimable, -> { open.where('expires_at > ?', Time.current) }

  validates :source, inclusion: { in: SOURCES }
  validates :expires_at, presence: true
  validate :exactly_one_owner

  def self.roll!(pokemon:, user: nil, guest_token: nil, source: 'browse')
    create!(pokemon:, user:, guest_token:, source:, expires_at: EXPIRES_IN.from_now)
  end

  def self.for_catch_token(token)
    find_signed(token, purpose: CATCH_PURPOSE)
  end

  def catch_token
    signed_id(purpose: CATCH_PURPOSE, expires_in: EXPIRES_IN)
  end

  def claimable?
    open? && expires_at.future?
  end

  # True only for the one request that moves this row from open to caught; double submits and races get false.
  def claim!
    with_lock do
      next false unless claimable?

      update!(status: :caught)
      true
    end
  end

  private

  def exactly_one_owner
    return if user_id.present? ^ guest_token.present?

    errors.add(:base, :owner, message: 'must belong to a user or a guest, not both')
  end
end
