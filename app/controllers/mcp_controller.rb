# frozen_string_literal: true

require 'stringio'

# Streamable HTTP MCP. Bearer auth, scopes, and the write switch are the same as the REST API.
class McpController < Api::V1::BaseController
  ORIGINS = %w[https://agent.meta.ai https://muse.ai https://chatgpt.com https://chat.openai.com https://claude.ai https://claude.com].freeze
  LOCAL_ORIGINS = %w[http://localhost:6274 http://127.0.0.1:6274].freeze

  def show
    head :method_not_allowed
  end

  def create
    status, headers, body = transport.call(transport_env)
    self.status = status
    headers.each { |key, value| response.set_header(key, value) }
    self.response_body = body
  end

  def destroy
    head :method_not_allowed
  end

  private

  def render_api_error(status, code, details: nil)
    if status == :unauthorized
      response.set_header('WWW-Authenticate', %(Bearer realm="baka", resource_metadata="#{oauth_metadata_url}"))
    end
    super
  end

  def oauth_metadata_url
    "#{request.base_url}/.well-known/oauth-protected-resource/mcp"
  end

  def read_request?
    return true unless request.post?

    Api::Mcp::RequestKind.read?(request.raw_post)
  end

  def logged_chapter_id
    text = tool_result_text
    return if text.blank?

    payload = JSON.parse(text)
    payload['id'] if payload.is_a?(Hash)
  rescue JSON::ParserError, TypeError
    nil
  end

  def tool_result_text
    raw = Array(response.body).join
    json = raw.start_with?('{') ? raw : raw[/^data: (\{.*\})/m, 1]
    return if json.blank?

    JSON.parse(json).dig('result', 'content', 0, 'text')
  rescue JSON::ParserError, TypeError
    nil
  end

  def transport
    MCP::Server::Transports::StreamableHTTPTransport.new(
      Api::Mcp::Server.build(user: Current.user, token: Current.api_token),
      stateless: true, allowed_hosts: [request.host], allowed_origins: origins
    )
  end

  def origins
    Rails.env.local? ? ORIGINS + LOCAL_ORIGINS : ORIGINS
  end

  def transport_env
    raw = request.raw_post
    request.env.merge('rack.input' => StringIO.new(raw), 'CONTENT_LENGTH' => raw.bytesize.to_s)
  end
end
