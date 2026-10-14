# frozen_string_literal: true

require 'test_helper'

class ScanlatorUserTest < ActiveSupport::TestCase
  setup { @user = users(:user_two) }

  test 'leaving the last team revokes keys and connected chats' do
    token = ApiToken.issue!(user: @user, name: 'Чат', scopes: %w[chapters:read chapters:write])
    access = oauth_token
    grant = oauth_grant(access.application)

    @user.scanlator_users.destroy_all

    assert token.reload.revoked_at
    assert access.reload.revoked_at
    assert grant.reload.revoked_at
  end

  test 'leaving one team keeps access while another team remains' do
    ScanlatorUser.create!(user: @user, scanlator: scanlators(:one))
    token = ApiToken.issue!(user: @user, name: 'Чат', scopes: %w[chapters:read chapters:write])

    @user.scanlator_users.find_by!(scanlator: scanlators(:two)).destroy

    assert_nil token.reload.revoked_at
  end

  private

  def oauth_token
    application = Doorkeeper::Application.create!(
      name: 'ChatGPT', redirect_uri: 'https://chatgpt.com/connector/oauth/callback',
      uid: "app-#{SecureRandom.hex(8)}", secret: SecureRandom.hex(16)
    )
    Doorkeeper::AccessToken.create!(
      application:, resource_owner_id: @user.id, token: SecureRandom.hex(16),
      expires_in: 2.hours.to_i, scopes: 'chapters:read'
    )
  end

  def oauth_grant(application)
    Doorkeeper::AccessGrant.create!(
      application:, resource_owner_id: @user.id, redirect_uri: application.redirect_uri,
      expires_in: 10.minutes.to_i, scopes: 'chapters:read', token: SecureRandom.hex(16)
    )
  end
end
