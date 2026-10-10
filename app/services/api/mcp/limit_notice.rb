# frozen_string_literal: true

module Api
  module Mcp
    # A rate-limit the model can read. HTTP 429 never reaches the chat, so /mcp answers in-band.
    class LimitNotice
      def self.payload(raw, message)
        new(raw, message).payload
      end

      def initialize(raw, message)
        @message = message
        @rpc = parse(raw)
      end

      def payload
        tool_call? ? tool_result : rpc_error
      end

      private

      def tool_call?
        @rpc['method'] == 'tools/call'
      end

      def tool_result
        text = JSON.generate({ error: { code: 'rate_limited', message: @message, details: {} } })
        { jsonrpc: '2.0', id: @rpc['id'], result: { content: [{ type: 'text', text: }], isError: true } }
      end

      def rpc_error
        { jsonrpc: '2.0', id: @rpc['id'], error: { code: -32_000, message: @message } }
      end

      def parse(raw)
        parsed = JSON.parse(raw.to_s)
        parsed.is_a?(Hash) ? parsed : {}
      rescue JSON::ParserError, TypeError
        {}
      end
    end
  end
end
