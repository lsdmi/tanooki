# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Publishes or schedules one chapter. Draft stays the default everywhere else.
      class PublishChapter < MCP::Tool
        extend Hints

        tool_name 'publish_chapter'
        title 'Publish chapter'
        description 'Publishes one chapter, or schedules it when published_at is in the future. Destructive. ' \
                    'Needs chapters:publish. Pass version from get_chapter. Show edit_url afterwards.'
        input_schema(
          properties: {
            chapter: { type: 'integer', description: 'Chapter id' },
            version: { type: 'string', description: 'version from the last read' },
            published_at: { type: 'string', description: 'ISO 8601 schedule, in the future. Omit to publish now' }
          },
          required: %w[chapter version]
        )
        writes(destructive: true)

        def self.call(chapter:, version:, server_context:, published_at: nil)
          Result.capture { publish(chapter, version, published_at, Actor.from(server_context)) }
        end

        def self.publish(chapter_id, version, published_at, actor)
          actor.permit!('chapters:write')
          record = actor.access.chapter!(chapter_id)
          params = { status: 'published', version: }
          params[:published_at] = published_at if published_at.present?
          outcome = Chapters::Update.call(user: actor.user, token: actor.token, chapter: record, params:)
          Chapters::Serialize.full(outcome.chapter, changes: outcome.changes, diff: outcome.diff)
        end
      end
    end
  end
end
