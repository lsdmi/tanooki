# frozen_string_literal: true

module Api
  module Mcp
    # A POST /mcp is a write only when it calls a tool that changes a chapter or uploads an image.
    class RequestKind
      READ_TOOLS = %w[whoami list_my_fictions list_chapters get_chapter get_chapters chapter_diff].freeze

      def self.read?(raw)
        new(raw).read?
      end

      def initialize(raw)
        @raw = raw.to_s
      end

      def read?
        messages&.none? { |message| write?(message) } == true
      end

      private

      def messages
        parsed = JSON.parse(@raw)
        parsed.is_a?(Array) ? parsed : [parsed]
      rescue JSON::ParserError, TypeError
        nil
      end

      def write?(message)
        return false unless message.is_a?(Hash) && message['method'] == 'tools/call'

        READ_TOOLS.exclude?(message.dig('params', 'name').to_s)
      end
    end
  end
end
