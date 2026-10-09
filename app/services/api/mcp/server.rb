# frozen_string_literal: true

module Api
  module Mcp
    # One stateless MCP server for the current token. It shares the Phase 2 services with REST.
    class Server
      INSTRUCTIONS = 'Draft is the default. Call list_chapters before create_chapter. ' \
                     'Prefer edit_paragraphs over update_chapter for a fix. ' \
                     'After a write, show edit_url and what changed. One chapter per write.'

      TOOLS = [
        Tools::Whoami, Tools::ListMyFictions, Tools::ListChapters, Tools::GetChapter, Tools::GetChapters,
        Tools::CreateChapter, Tools::EditParagraphs, Tools::UpdateChapter, Tools::ChapterDiff,
        Tools::RevertChapter, Tools::PublishChapter, Tools::UploadImageFromUrl
      ].freeze

      PROMPTS = [Prompts::PublishTranslation, Prompts::ProofreadRange].freeze

      def self.build(user:, token:)
        MCP::Server.new(
          name: 'baka', title: 'Бака', version: '1.0.0', instructions: INSTRUCTIONS,
          tools: TOOLS, prompts: PROMPTS, resources: [FormattingGuide], server_context: { user:, token: }
        )
      end
    end
  end
end
