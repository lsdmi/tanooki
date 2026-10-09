# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Paragraph diff against one revision, or the latest revision when none is given.
      class ChapterDiff < MCP::Tool
        extend Hints

        tool_name 'chapter_diff'
        title 'Chapter diff'
        description 'What changed since a revision. Omit revision for the latest snapshot. Needs chapters:read.'
        input_schema(
          properties: {
            chapter: { type: 'integer', description: 'Chapter id' },
            revision: { type: 'integer', description: 'Revision id. Default: the latest' }
          },
          required: ['chapter']
        )
        read_only

        def self.call(chapter:, server_context:, revision: nil)
          Result.capture { diff(chapter, revision, Actor.from(server_context)) }
        end

        def self.diff(chapter_id, revision_id, actor)
          actor.permit!('chapters:read')
          record = actor.access.chapter!(chapter_id)
          snapshot = snapshot_for(actor, record, revision_id)
          { revision: snapshot.id, paragraphs: Chapters::Diff.call(record, snapshot) }
        end

        def self.snapshot_for(actor, record, revision_id)
          snapshot = if revision_id.present?
                       actor.access.revision(record.id, revision_id)
                     else
                       record.revisions.order(created_at: :desc, id: :desc).first
                     end
          snapshot || raise(Error.new('not_found', :not_found))
        end
      end
    end
  end
end
