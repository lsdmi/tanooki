# frozen_string_literal: true

module Api
  module Mcp
    module Prompts
      # Reads a short range, fixes one chapter at a time, then reports the diffs.
      class ProofreadRange < MCP::Prompt
        prompt_name 'proofread_range'
        title 'Вичитати діапазон розділів'
        description 'Check a chapter range, fix what needs fixing, then re-read.'
        arguments [
          MCP::Prompt::Argument.new(name: 'fiction', description: 'Fiction id or slug', required: true),
          MCP::Prompt::Argument.new(name: 'from', description: 'First chapter number', required: true),
          MCP::Prompt::Argument.new(name: 'to', description: 'Last chapter number', required: true),
          MCP::Prompt::Argument.new(name: 'issue', description: 'What to look for', required: true)
        ]

        def self.template(args)
          MCP::Prompt::Result.new(messages: [MCP::Prompt::Message.new(role: 'user', content: message(args))])
        end

        def self.message(args)
          {
            type: 'text',
            text: <<~TEXT
              Check chapters #{args[:from]}–#{args[:to]} of fiction #{args[:fiction]} for: #{args[:issue]}.
              Read them with get_chapters. Fix one chapter at a time with edit_paragraphs, using the version from the read.
              Do not replace a whole chapter. Then re-read the changed chapters and list each diff.
            TEXT
          }
        end
      end
    end
  end
end
