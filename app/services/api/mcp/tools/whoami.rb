# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Who the token is. Any valid token may call it.
      class Whoami < MCP::Tool
        extend Hints

        tool_name 'whoami'
        title 'Who am I'
        description 'The signed-in user, their teams, and the token scopes. Call this first to confirm the connection.'
        read_only

        def self.call(server_context:)
          Result.capture do
            actor = Actor.from(server_context)
            profile(actor)
          end
        end

        def self.profile(actor)
          token = actor.token
          {
            user: { id: actor.user.id, name: actor.user.name },
            teams: actor.user.scanlators.order(:title).map { |team| { id: team.id, name: team.title } },
            token: { prefix: token.token_prefix, scopes: token.scopes, expires_at: token.expires_at.iso8601 }
          }
        end
      end
    end
  end
end
