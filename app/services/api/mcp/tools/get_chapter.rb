# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # One chapter, with numbered paragraphs and a version for the next write.
      class GetChapter < MCP::Tool
        extend Hints

        tool_name 'get_chapter'
        title 'Get chapter'
        description 'One chapter this token can see: paragraphs, version, and edit_url. ' \
                    'Pass chapter_id, or fiction plus number. Several matches is an error. ' \
                    'Needs chapters:read.'
        input_schema(
          properties: {
            chapter_id: { type: 'integer', description: 'Chapter id' },
            fiction: { type: 'string', description: 'Fiction id or slug, together with number' },
            number: { type: 'number', description: 'Chapter number' },
            volume: { type: 'number', description: 'Volume, when the number is not unique' }
          }
        )
        read_only

        def self.call(server_context:, chapter_id: nil, fiction: nil, number: nil, volume: nil)
          Result.capture do
            actor = Actor.from(server_context).permit!('chapters:read')
            find(actor, chapter_id, fiction, number, volume)
          end
        end

        def self.find(actor, chapter_id, fiction, number, volume)
          return Chapters::Serialize.full(actor.access.chapter!(chapter_id)) if chapter_id.present?

          raise Error.new('invalid', :unprocessable_entity) if fiction.blank? || number.blank?

          Chapters::Catalog.new(actor.user).by_number(fiction, number, volume:)
        end
      end
    end
  end
end
