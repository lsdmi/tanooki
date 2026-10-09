# frozen_string_literal: true

# Shared requests for the ChatGPT OAuth flow tests.
module OauthFlowHelper
  REDIRECT = 'https://chatgpt.com/connector/oauth/callback'
  REQUESTED = 'chapters:read chapters:write chapters:publish images:write offline_access'

  def request_base
    'http://www.example.com'
  end

  def registration(redirect_uri)
    {
      client_name: 'ChatGPT', redirect_uris: [redirect_uri], token_endpoint_auth_method: 'none',
      grant_types: %w[authorization_code refresh_token], response_types: ['code']
    }
  end

  def register_client
    post '/oauth/register', params: registration(REDIRECT), as: :json

    assert_response :created
    response.parsed_body
  end

  def pkce_pair
    verifier = SecureRandom.alphanumeric(48)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    [verifier, challenge]
  end

  def authorize_params(client, challenge)
    {
      client_id: client['client_id'], redirect_uri: REDIRECT, response_type: 'code', scope: REQUESTED,
      code_challenge: challenge, code_challenge_method: 'S256', state: 'xyz'
    }
  end

  def connect!
    client = register_client
    verifier, challenge = pkce_pair
    sign_in users(:user_two)
    [client, exchange_code(client, verifier, authorization_code(client, challenge))]
  end

  def authorization_code(client, challenge)
    post '/oauth/authorize', params: authorize_params(client, challenge).merge(scope: %w[chapters:read chapters:write])
    Rack::Utils.parse_query(URI(response.location).query)['code']
  end

  def exchange_code(client, verifier, code)
    post '/oauth/token', params: {
      grant_type: 'authorization_code', code:, redirect_uri: REDIRECT,
      client_id: client['client_id'], code_verifier: verifier
    }
    response.parsed_body
  end

  def refresh_params(client, token)
    { grant_type: 'refresh_token', refresh_token: token['refresh_token'], client_id: client['client_id'] }
  end

  def bearer(secret)
    { 'Authorization' => "Bearer #{secret}", 'Accept' => 'application/json, text/event-stream' }
  end

  def rpc(method, **params)
    { jsonrpc: '2.0', id: 1, method:, params: }
  end

  def tool_json(secret, name, **arguments)
    post '/mcp', params: rpc('tools/call', name:, arguments:), headers: bearer(secret), as: :json
    text = json_body(response.body).dig('result', 'content', 0, 'text')
    JSON.parse(text)
  end

  def json_body(raw)
    json = raw.start_with?('{') ? raw : raw[/^data: (\{.*\})/m, 1]
    JSON.parse(json)
  end
end
