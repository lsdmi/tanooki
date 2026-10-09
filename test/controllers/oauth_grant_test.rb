# frozen_string_literal: true

require 'test_helper'

class OauthGrantTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include OauthFlowHelper

  test 'a granted token reads whoami and not another team' do
    _client, token = connect!
    profile = tool_json(token['access_token'], 'whoami')
    missed = tool_json(token['access_token'], 'get_chapter', chapter_id: chapters(:one).id)

    assert_equal users(:user_two).name, profile.dig('user', 'name')
    assert_not_includes token['scope'].to_s.split, 'chapters:publish'
    assert_equal 'not_found', missed.dig('error', 'code')
  end

  test 'an oauth draft keeps no api token row' do
    FictionScanlator.find_or_create_by!(fiction: fictions(:eighteen), scanlator: scanlators(:two))
    _client, token = connect!
    created = tool_json(
      token['access_token'], 'create_chapter', fiction: 'eighteen', number: 8804, content: 'Чернетка з абзацом.'
    )
    chapter = Chapter.find(created['id'])

    assert_equal 'mcp', chapter.created_via
    assert_nil chapter.api_token_id
  end

  test 'a fresh refresh token issues another access token' do
    client, token = connect!
    post '/oauth/token', params: refresh_params(client, token)

    assert_response :success
    assert_predicate response.parsed_body['access_token'], :present?
  end

  test 'a refresh token unused for 90 days is refused' do
    client, token = connect!
    travel 91.days
    post '/oauth/token', params: refresh_params(client, token)

    assert_response :bad_request
    assert_equal 'invalid_grant', response.parsed_body['error']
  end

  test 'studio lists the connection and revoke cuts it off' do
    client, token = connect!
    get studio_index_path(tab: 'teams')
    listed = response.body
    delete oauth_connection_path(client['client_id'])
    post '/mcp', params: rpc('tools/call', name: 'whoami', arguments: {}), headers: bearer(token['access_token']),
                 as: :json

    assert_includes listed, 'ChatGPT'
    assert_includes listed, I18n.t('oauth_connections.revoke')
    assert_response :unauthorized
  end
end
