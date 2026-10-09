# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Restores one revision and keeps a snapshot of what was overwritten.
      class RevertChapter < MCP::Tool
        extend Hints

        tool_name 'revert_chapter'
        title 'Revert chapter'
        description 'Restores one chapter to a revision. Destructive. A published chapter needs chapters:publish. ' \
                    'Show the reader what was restored.'
        input_schema(
          properties: {
            chapter: { type: 'integer', description: 'Chapter id' },
            revision: { type: 'integer', description: 'Revision id from chapter_diff or the revision list' }
          },
          required: %w[chapter revision]
        )
        writes(destructive: true)

        def self.call(chapter:, revision:, server_context:)
          Result.capture { restore(chapter, revision, Actor.from(server_context)) }
        end

        def self.restore(chapter_id, revision_id, actor)
          actor.permit!('chapters:write')
          record = actor.access.chapter!(chapter_id)
          snapshot = actor.access.revision(record.id, revision_id) || raise(Error.new('not_found', :not_found))
          outcome = Chapters::Revert.call(user: actor.user, token: actor.token, chapter: record, revision: snapshot)
          Chapters::Serialize.full(outcome.chapter, diff: { summary: 'reverted' })
        end
      end
    end
  end
end
