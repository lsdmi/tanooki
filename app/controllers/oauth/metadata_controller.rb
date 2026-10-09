# frozen_string_literal: true

module Oauth
  # OAuth discovery documents. The resource is the MCP endpoint.
  class MetadataController < ActionController::API
    def protected_resource
      render json: {
        resource: "#{base}/mcp",
        authorization_servers: [base],
        scopes_supported: RegisterClient::GRANTABLE,
        bearer_methods_supported: ['header']
      }
    end

    def authorization_server
      render json: {
        issuer: base, authorization_endpoint: "#{base}/oauth/authorize",
        token_endpoint: "#{base}/oauth/token", registration_endpoint: "#{base}/oauth/register",
        response_types_supported: ['code'], grant_types_supported: %w[authorization_code refresh_token],
        code_challenge_methods_supported: ['S256'], token_endpoint_auth_methods_supported: ['none'],
        scopes_supported: RegisterClient::GRANTABLE
      }
    end

    private

    def base
      request.base_url
    end
  end
end
