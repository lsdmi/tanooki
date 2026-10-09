# frozen_string_literal: true

module Api
  module Mcp
    module Prompts
      # Walks the assistant from a translation to one draft chapter.
      class PublishTranslation < MCP::Prompt
        prompt_name 'publish_translation'
        title 'Опублікувати переклад як чернетку'
        description 'Format a translation for Бака and create a draft of one chapter.'
        arguments [
          MCP::Prompt::Argument.new(name: 'fiction', description: 'Fiction id or slug', required: true),
          MCP::Prompt::Argument.new(name: 'number', description: 'Chapter number', required: true),
          MCP::Prompt::Argument.new(name: 'translation', description: 'The translated chapter', required: true)
        ]

        def self.template(args)
          MCP::Prompt::Result.new(messages: [MCP::Prompt::Message.new(role: 'user', content: message(args))])
        end

        def self.message(args)
          {
            type: 'text',
            text: <<~TEXT
              Read baka://formatting-guide. Call list_chapters for fiction #{args[:fiction]} before writing.
              Format this translation and create_chapter as a draft of chapter #{args[:number]}. Do not publish.
              Then show the edit_url.

              #{args[:translation]}
            TEXT
          }
        end
      end
    end
  end
end
