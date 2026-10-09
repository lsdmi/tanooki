# frozen_string_literal: true

require 'test_helper'

class OauthFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include OauthFlowHelper

  test 'discovery documents describe the mcp resource' do
    get '/.well-known/oauth-protected-resource/mcp'
    resource = response.parsed_body
    get '/.well-known/oauth-authorization-server'

    assert_equal "#{request_base}/mcp", resource['resource']
    assert_equal "#{request_base}/oauth/register", response.parsed_body['registration_endpoint']
    assert_includes response.parsed_body['code_challenge_methods_supported'], 'S256'
  end

  test 'the rest api stays silent about oauth' do
    get '/api/v1/me'

    assert_response :unauthorized
    assert_nil response.headers['WWW-Authenticate']
  end

  test 'a stranger redirect is refused' do
    post '/oauth/register', params: registration('https://evil.example/callback'), as: :json

    assert_response :bad_request
    assert_equal 'invalid_client_metadata', response.parsed_body['error']
  end

  test 'an unsigned visitor is sent to log in' do
    client = register_client
    get '/oauth/authorize', params: authorize_params(client, pkce_pair.last)

    assert_response :redirect
    assert_match %r{/login}, response.location
  end

  test 'an admin without a team cannot consent' do
    sign_in users(:user_one)
    users(:user_one).scanlator_users.delete_all
    client = register_client
    get '/oauth/authorize', params: authorize_params(client, pkce_pair.last)

    assert_response :forbidden
    assert_includes response.body, I18n.t('oauth_consent.needs_team')
  end

  test 'consent uses the site chrome' do
    sign_in users(:user_two)
    client = register_client
    get '/oauth/authorize', params: authorize_params(client, pkce_pair.last)

    assert_includes response.body, 'Про Бака'
  end

  test 'publish stays unchecked until the member opts in' do
    sign_in users(:user_two)
    client = register_client
    get '/oauth/authorize', params: authorize_params(client, pkce_pair.last)

    assert_response :success
    assert_select 'h1', text: 'Дозволити ChatGPT керувати розділами ваших команд?'
    assert_select '#oauth_scope_chapters_publish:not([checked])'
  end
end
