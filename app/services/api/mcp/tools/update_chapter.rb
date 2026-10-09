# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Partial update. Paragraph edits are the better tool for a small fix.
      class UpdateChapter < MCP::Tool
        extend Hints

        tool_name 'update_chapter'
        title 'Update chapter'
        description 'Changes fields of one chapter. Prefer edit_paragraphs for a wording fix. ' \
                    'Pass version from get_chapter. A published chapter needs chapters:publish. Then show edit_url.'
        input_schema(
          properties: {
            chapter: { type: 'integer', description: 'Chapter id' },
            version: { type: 'string', description: 'version from the last read' },
            title: { type: 'string' },
            content: { type: 'string', description: 'Markdown for the whole body' },
            content_format: { type: 'string', description: 'markdown (default) or html' },
            number: { type: 'number' },
            volume_number: { type: 'number' },
            status: { type: 'string', description: 'draft or published' },
            published_at: { type: 'string', description: 'ISO 8601, in the future' },
            scanlator_ids: { type: 'array', items: { type: 'integer' } }
          },
          required: %w[chapter version]
        )
        writes

        def self.call(chapter:, version:, server_context:, **options)
          Result.capture { change(chapter, version, options, Actor.from(server_context)) }
        end

        def self.change(chapter_id, version, options, actor)
          actor.permit!('chapters:write')
          record = actor.access.chapter!(chapter_id)
          outcome = Chapters::Update.call(
            user: actor.user, token: actor.token, chapter: record, params: options.merge(version:)
          )
          Chapters::Serialize.full(outcome.chapter, changes: outcome.changes, diff: outcome.diff)
        end
      end
    end
  end
end
