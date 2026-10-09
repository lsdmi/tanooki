# frozen_string_literal: true

module Api
  # A Doorkeeper access token seen the same way as an ApiToken: user, scopes, and team check.
  # It is not an ApiToken, so chapter rows keep api_token_id empty.
  class OauthAccess
    def self.from_secret(secret)
      return if secret.blank?

      record = Doorkeeper::AccessToken.by_token(secret)
      return if record.nil? || !record.accessible? || record.resource_owner_id.blank?

      user = User.find_by(id: record.resource_owner_id)
      new(record, user) if user
    end

    def initialize(record, user)
      @record = record
      @user = user
    end

    attr_reader :user

    def id
      "oauth-#{record.id}"
    end

    def token_prefix
      'oauth'
    end

    def scopes
      record.scopes.to_a
    end

    delegate :expires_at, to: :record

    def permits?(scope)
      scope = scope.to_s
      return false unless scopes.include?(scope)
      return false if ApiToken::WRITE_SCOPES.include?(scope) && user.scanlators.none?

      true
    end

    private

    attr_reader :record
  end
end
