# frozen_string_literal: true

module Api
  module Mcp
    # The user and token for one MCP call. Lookups go through Api::Access, never the admin helpers.
    class Actor
      def self.from(server_context)
        new(server_context[:user], server_context[:token])
      end

      def initialize(user, token)
        @user = user
        @token = token
      end

      def permit!(scope)
        raise Error.new('forbidden', :forbidden) unless token&.permits?(scope)

        self
      end

      def access
        @access ||= Access.new(user)
      end

      attr_reader :user, :token
    end
  end
end
