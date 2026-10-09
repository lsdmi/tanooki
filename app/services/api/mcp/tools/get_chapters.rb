# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Up to five chapters for a range check such as 250–254.
      class GetChapters < MCP::Tool
        extend Hints

        tool_name 'get_chapters'
        title 'Get chapters'
        description 'Up to 5 chapters in a number range, with paragraphs. Use this to proofread a range. ' \
                    'Writes are still one chapter at a time. Needs chapters:read.'
        input_schema(
          properties: {
            fiction: { type: 'string', description: 'Fiction id or slug' },
            from: { type: 'number', description: 'First chapter number' },
            to: { type: 'number', description: 'Last chapter number' }
          },
          required: %w[fiction from to]
        )
        read_only

        def self.call(fiction:, from:, to:, server_context:)
          Result.capture do
            actor = Actor.from(server_context).permit!('chapters:read')
            { chapters: Chapters::Catalog.new(actor.user).batch(fiction, from:, to:) }
          end
        end
      end
    end
  end
end
