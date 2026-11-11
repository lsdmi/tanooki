# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Chapter list without bodies. Call this before creating a chapter.
      class ListChapters < MCP::Tool
        extend Hints

        tool_name 'list_chapters'
        title 'List chapters'
        description 'Catalog only: id, number, title, status, volume, teams — no html, paragraphs, or version. ' \
                    'Call this before create_chapter and to discover numbers. For text or version use get_chapter / ' \
                    'get_chapters. Another team’s chapters are absent. Needs chapters:read.'
        input_schema(
          properties: {
            fiction: { type: 'string', description: 'Fiction id or slug' },
            team_id: { type: 'integer', description: 'Limit to one of the caller’s teams' },
            from: { type: 'number', description: 'First chapter number' },
            to: { type: 'number', description: 'Last chapter number' }
          },
          required: ['fiction']
        )
        read_only

        def self.call(fiction:, server_context:, team_id: nil, from: nil, to: nil)
          Result.capture do
            actor = Actor.from(server_context).permit!('chapters:read')
            { chapters: Chapters::Catalog.new(actor.user).summaries(fiction, team_id:, from:, to:) }
          end
        end
      end
    end
  end
end
