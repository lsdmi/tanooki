# frozen_string_literal: true

module Api
  module Mcp
    # Turns a service result or an Api::Error into a tool response the model can read.
    module Result
      def self.capture
        MCP::Tool::Response.new([{ 'type' => 'text', 'text' => JSON.generate(yield) }])
      rescue Error => e
        MCP::Tool::Response.new([{ 'type' => 'text', 'text' => JSON.generate(body(e)) }], error: true)
      end

      def self.capture_image
        payload = yield
        MCP::Tool::Response.new([text_item(payload.fetch(:text)), image_item(payload)])
      rescue Error => e
        MCP::Tool::Response.new([text_item(body(e))], error: true)
      end

      def self.text_item(text)
        { 'type' => 'text', 'text' => JSON.generate(text) }
      end

      def self.image_item(payload)
        encoded = Base64.strict_encode64(payload.fetch(:binary))
        { 'type' => 'image', 'data' => encoded, 'mimeType' => payload.fetch(:mime) }
      end

      def self.body(error)
        details = error.details || {}
        message = I18n.t("api.errors.#{error.code}", **details.symbolize_keys)
        { error: { code: error.code, message:, details: } }
      end
    end
  end
end
