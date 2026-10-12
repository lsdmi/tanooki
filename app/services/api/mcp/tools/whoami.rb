# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Who the token is. Any valid token may call it.
      class Whoami < MCP::Tool
        extend Hints

        tool_name 'whoami'
        title 'Who am I'
        description 'The signed-in user, their teams, token scopes, and remaining limits. ' \
                    'Tell the user those numbers when they ask or before many published edits.'
        read_only

        def self.call(server_context:)
          Result.capture do
            actor = Actor.from(server_context)
            profile(actor)
          end
        end

        def self.profile(actor)
          {
            user: { id: actor.user.id, name: actor.user.name },
            teams: teams(actor.user),
            token: token_payload(actor.token),
            limits: Limits::Usage.snapshot(actor.user)
          }
        end

        def self.teams(user)
          user.scanlators.order(:title).map { |team| { id: team.id, name: team.title } }
        end

        def self.token_payload(token)
          { prefix: token.token_prefix, scopes: token.scopes, expires_at: token.expires_at.iso8601 }
        end
      end
    end
  end
end
