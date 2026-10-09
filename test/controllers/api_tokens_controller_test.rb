# frozen_string_literal: true

require 'test_helper'

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'a team member creates a token and sees the secret once' do
    sign_in users(:user_two)

    post api_tokens_path, params: token_params
    follow_redirect!
    secret = css_select('[data-api-token-secret]').first['value']

    assert_match(/\Abaka_/, secret)
    assert_includes response.body, 'Claude'
    assert_includes response.body, secret.first(8)
  end

  test 'the secret is not shown on the next visit' do
    sign_in users(:user_two)
    post api_tokens_path, params: token_params
    follow_redirect!

    get studio_index_path(tab: 'teams')

    assert_select '[data-api-token-secret]', count: 0
    assert_includes response.body, 'Claude'
    assert_includes response.body, I18n.t('api_tokens.experimental')
  end

  test 'a reader without a team does not get the form' do
    sign_in users(:user_one_one_zero)

    get studio_index_path(tab: 'teams')

    assert_response :success
    assert_select 'form[action=?]', api_tokens_path, count: 0
  end

  test 'the owner can revoke a token' do
    owner = users(:user_two)
    token = ApiToken.issue!(user: owner, name: 'Claude', scopes: ApiToken::DEFAULT_SCOPES)
    sign_in owner

    delete api_token_path(token)

    assert_redirected_to studio_index_path(tab: 'teams')
    assert_not_predicate token.reload, :usable?
  end

  test 'another user cannot revoke the token' do
    token = ApiToken.issue!(user: users(:user_two), name: 'Інший', scopes: ApiToken::DEFAULT_SCOPES)
    sign_in users(:user_one)

    delete api_token_path(token)

    assert_response :not_found
    assert_predicate token.reload, :usable?
  end

  test 'the publish scope is marked as a live edit' do
    user = users(:user_two)
    ApiToken.issue!(user:, name: 'Публікація', scopes: %w[chapters:read chapters:publish])
    sign_in user

    get studio_index_path(tab: 'teams')

    assert_includes response.body, I18n.t('api_tokens.publish_warning')
    assert_includes response.body, I18n.t('api_tokens.live_edits')
  end

  test 'a draft token is not marked as a live edit' do
    user = users(:user_two)
    ApiToken.issue!(user:, name: 'Чернетки', scopes: ApiToken::DEFAULT_SCOPES)
    sign_in user

    get studio_index_path(tab: 'teams')

    assert_not_includes response.body, I18n.t('api_tokens.live_edits')
  end

  private

  def token_params
    { api_token: { name: 'Claude', expires_in: '30', scopes: %w[chapters:read chapters:write] } }
  end
end
