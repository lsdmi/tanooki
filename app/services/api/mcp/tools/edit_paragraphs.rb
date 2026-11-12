# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Replaces numbered blocks; text-only edits keep the block’s HTML (styles, notes).
      class EditParagraphs < MCP::Tool
        extend Hints

        tool_name 'edit_paragraphs'
        title 'Edit paragraphs'
        description 'Prefer this over update_chapter for fixes. n starts at 1. ' \
                    'old must match paragraphs from get_chapter. ' \
                    'Text-only edits (same **/* markup) keep HTML styles and notes; ' \
                    'identical old and new change nothing. An empty new deletes the block. ' \
                    'New markup or a blank-line split rebuilds that block from Markdown. ' \
                    'Pass version from get_chapter. One chapter per call. ' \
                    'A published chapter needs chapters:publish. Show the diff afterwards.'
        input_schema(
          properties: {
            chapter: { type: 'integer', description: 'Chapter id' },
            version: { type: 'string', description: 'version from the last read' },
            edits: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  n: { type: 'integer' },
                  old: { type: 'string' },
                  new: { type: 'string', description: 'Markdown. Empty deletes the block' }
                },
                required: %w[n old new]
              }
            }
          },
          required: %w[chapter version edits]
        )
        writes

        def self.call(chapter:, version:, edits:, server_context:)
          Result.capture { change(chapter, version, edits, Actor.from(server_context)) }
        end

        def self.change(chapter_id, version, edits, actor)
          actor.permit!('chapters:write')
          record = actor.access.chapter!(chapter_id)
          outcome = Chapters::EditParagraphs.call(
            user: actor.user, token: actor.token, chapter: record, params: { version:, edits: }
          )
          Chapters::Serialize.full(outcome.chapter, changes: outcome.changes, diff: outcome.diff)
        end
      end
    end
  end
end
