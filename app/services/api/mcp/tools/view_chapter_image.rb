# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # One still frame of an image that is already in a chapter this token can read.
      class ViewChapterImage < MCP::Tool
        extend Hints

        tool_name 'view_chapter_image'
        title 'View chapter image'
        description 'Shows one image already in a chapter this token can read. ' \
                    'Pass chapter_id and the img src from the chapter html, or index starting at 1. ' \
                    'Call it only when the user asks about a picture. A GIF is one still frame plus the frame count. ' \
                    'Needs chapters:read.'
        input_schema(
          properties: {
            chapter_id: { type: 'integer' },
            url: { type: 'string', description: 'The img src from this chapter html.' },
            index: { type: 'integer', description: '1-based image index when url is omitted.' }
          },
          required: ['chapter_id']
        )
        read_only

        def self.call(server_context:, chapter_id:, url: nil, index: nil)
          Result.capture_image do
            actor = Actor.from(server_context).permit!('chapters:read')
            present(Chapters::ViewImage.call(user: actor.user, chapter_id:, url:, index:))
          end
        end

        def self.present(preview)
          {
            text: { animated: preview.animated, frames: preview.frames, duration_ms: preview.duration_ms,
                    note: note(preview) }.compact,
            binary: preview.binary, mime: preview.mime
          }
        end

        def self.note(preview)
          return unless preview.animated

          'Це один кадр. Кількість кадрів означає, що картинка рухається. Сам рух переглянути не можна.'
        end

        private_class_method :present, :note
      end
    end
  end
end
