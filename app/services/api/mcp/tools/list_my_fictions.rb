# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Fictions the caller’s teams work on.
      class ListMyFictions < MCP::Tool
        extend Hints

        tool_name 'list_my_fictions'
        title 'List my fictions'
        description 'Fictions this token’s teams translate. Pass query to search by title. Needs chapters:read.'
        input_schema(properties: { query: { type: 'string', description: 'Title search' } })
        read_only

        def self.call(server_context:, query: nil)
          Result.capture do
            actor = Actor.from(server_context).permit!('chapters:read')
            { fictions: Fictions::MineQuery.call(actor.user, query:) }
          end
        end
      end
    end
  end
end
