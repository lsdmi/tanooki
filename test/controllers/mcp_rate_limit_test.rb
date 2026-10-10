# frozen_string_literal: true

require 'test_helper'

class McpRateLimitTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_two)
    @token, @secret = issue
  end

  teardown do
    Rails.cache.delete(write_limit_key)
    Rails.cache.delete(read_limit_key)
  end

  test 'a rate limited tool call tells the model why' do
    Rails.cache.increment(write_limit_key, Api::V1::BaseController::WRITES_PER_MINUTE, expires_in: 1.minute)
    body = call('tools/call', name: 'create_chapter', arguments: { fiction: 'eighteen', number: 1, content: 'x' })
    text = body.dig('result', 'content', 0, 'text')

    assert_response :success
    assert body.dig('result', 'isError')
    assert_match(/30 на хвилину/, text)
  end

  test 'a rate limited listing names the read limit' do
    Rails.cache.increment(read_limit_key, Api::V1::BaseController::READS_PER_MINUTE, expires_in: 1.minute)
    body = call('tools/list')

    assert_response :success
    assert_match(/300 на хвилину/, body.dig('error', 'message'))
  end

  private

  def issue
    token = ApiToken.issue!(user: @user, name: 'Claude', scopes: %w[chapters:read chapters:write])
    [token, token.secret]
  end

  def write_limit_key
    "rate-limit:api/v1:write:#{@token.id}"
  end

  def read_limit_key
    "rate-limit:api/v1:read:#{@token.id}"
  end

  def auth
    { 'Authorization' => "Bearer #{@secret}", 'Accept' => 'application/json, text/event-stream' }
  end

  def call(method, **params)
    post '/mcp', params: { jsonrpc: '2.0', id: 1, method:, params: }, headers: auth, as: :json
    json = response.body.start_with?('{') ? response.body : response.body[/^data: (\{.*\})/m, 1]
    JSON.parse(json)
  end
end
