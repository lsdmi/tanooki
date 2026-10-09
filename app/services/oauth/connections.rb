# frozen_string_literal: true

module Oauth
  # One row per connected OAuth client for the Studio list.
  class Connections
    def self.for(user)
      tokens = Doorkeeper::AccessToken.where(resource_owner_id: user.id, revoked_at: nil)
                                      .includes(:application).order(created_at: :desc)
      tokens.group_by(&:application).filter_map { |application, group| new(application, group) if application }
    end

    def initialize(application, tokens)
      @application = application
      @tokens = tokens
    end

    delegate :name, :uid, to: :application

    def scopes
      tokens.first.scopes.to_a - ['offline_access']
    end

    def connected_at
      tokens.first.created_at
    end

    private

    attr_reader :application, :tokens
  end
end
