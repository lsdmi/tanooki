# frozen_string_literal: true

# Personal access token. The secret is shown once at creation; lookups use its SHA-256 digest.
# Any current team member can create one. Membership is checked again on each use.
class ApiToken < ApplicationRecord
  include NormalizesWhitespace

  PREFIX = 'baka_'
  PREFIX_LENGTH = 8
  SCOPES = %w[chapters:read chapters:write chapters:publish images:write].freeze
  WRITE_SCOPES = %w[chapters:write chapters:publish images:write].freeze
  DEFAULT_SCOPES = %w[chapters:read chapters:write].freeze
  MAX_ACTIVE = 5
  DEFAULT_TTL = 90.days
  MAX_TTL = 1.year
  BASE58 = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

  belongs_to :user

  normalizes_squished :name

  before_validation :normalize_scopes

  scope :active, -> { where(revoked_at: nil).where(expires_at: Time.current..) }

  validates :name, presence: true, length: { maximum: 40 }
  validates :token_digest, :token_prefix, :expires_at, presence: true
  validate :known_scopes
  validate :member_of_a_team, on: :create
  validate :within_active_limit, on: :create
  validate :expiry_in_range

  attr_reader :secret

  def self.issue!(user:, name:, scopes:, expires_at: DEFAULT_TTL.from_now)
    secret = generate_secret
    token = create!(
      user:, name:, scopes:, expires_at:,
      token_digest: digest(secret), token_prefix: secret.first(PREFIX_LENGTH)
    )
    token.instance_variable_set(:@secret, secret)
    token
  end

  # Digest lookup only. A revoked or expired token is the same as an unknown secret.
  def self.authenticate(secret)
    secret = secret.to_s
    return if secret.blank? || !secret.start_with?(PREFIX)

    active.find_by(token_digest: digest(secret))
  end

  def self.digest(secret)
    Digest::SHA256.hexdigest(secret)
  end

  def revoke!
    update!(revoked_at: Time.current) if revoked_at.nil?
  end

  def usable?
    revoked_at.nil? && expires_at.future?
  end

  # A member who left every team keeps read scope and loses write scope on the next call.
  def permits?(scope)
    scope = scope.to_s
    return false unless usable? && scopes.include?(scope)
    return false if WRITE_SCOPES.include?(scope) && user.scanlators.none?

    true
  end

  private

  def self.generate_secret
    "#{PREFIX}#{encode_base58(SecureRandom.random_bytes(32))}"
  end

  def self.encode_base58(bytes)
    integer = bytes.unpack1('H*').to_i(16)
    encoded = +''
    while integer.positive?
      integer, remainder = integer.divmod(58)
      encoded.prepend(BASE58[remainder])
    end
    ('1' * bytes.bytes.take_while(&:zero?).count) + encoded
  end

  private_class_method :generate_secret, :encode_base58

  def normalize_scopes
    self.scopes = Array(scopes).compact_blank.map(&:to_s).uniq
  end

  def known_scopes
    list = Array(scopes)
    errors.add(:scopes, :invalid) if list.empty? || (list - SCOPES).any?
  end

  def member_of_a_team
    errors.add(:base, :no_team) if user&.scanlators&.none?
  end

  def within_active_limit
    return if user.blank?

    errors.add(:base, :too_many) if user.api_tokens.active.count >= MAX_ACTIVE
  end

  def expiry_in_range
    return if expires_at.blank?

    errors.add(:expires_at, :too_soon) unless expires_at.future?
    errors.add(:expires_at, :too_far) if expires_at > MAX_TTL.from_now + 1.minute
  end
end
