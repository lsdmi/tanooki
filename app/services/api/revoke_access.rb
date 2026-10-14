# frozen_string_literal: true

module Api
  # Drops every key and connected chat for a member who no longer belongs to a team.
  class RevokeAccess
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      revoke_keys
      revoke_oauth
    end

    private

    attr_reader :user

    def revoke_keys
      user.api_tokens.active.find_each(&:revoke!)
    end

    def revoke_oauth
      Doorkeeper::AccessToken.where(resource_owner_id: user.id, revoked_at: nil).find_each(&:revoke)
      Doorkeeper::AccessGrant.where(resource_owner_id: user.id, revoked_at: nil).find_each(&:revoke)
    end
  end
end
