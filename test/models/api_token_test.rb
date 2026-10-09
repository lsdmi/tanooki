# frozen_string_literal: true

require 'test_helper'

class ApiTokenTest < ActiveSupport::TestCase
  test 'lookup uses the digest and never the secret' do
    token, secret = issue

    assert_nil ApiToken.find_by(token_digest: secret)
    assert_equal token, ApiToken.find_by(token_digest: Digest::SHA256.hexdigest(secret))
    assert_equal token, ApiToken.authenticate(secret)
  end

  test 'the secret is shown once and starts with the stored prefix' do
    token, secret = issue

    assert_match(/\Abaka_[1-9A-HJ-NP-Za-km-z]+\z/, secret)
    assert_equal secret.first(8), token.token_prefix
    assert_not_includes token.reload.attributes.keys, 'secret'
  end

  test 'a revoked token is rejected' do
    token, secret = issue
    token.revoke!

    assert_nil ApiToken.authenticate(secret)
    assert_not_predicate token, :usable?
  end

  test 'an expired token is rejected' do
    token, secret = issue

    travel_to token.expires_at + 1.minute do
      assert_nil ApiToken.authenticate(secret)
    end
  end

  test 'a member who left every team can still read' do
    user = users(:user_two)
    token, secret = issue(user:)
    user.scanlator_users.destroy_all

    assert_equal token, ApiToken.authenticate(secret)
    assert ApiToken.authenticate(secret).permits?('chapters:read')
  end

  test 'a member who left every team cannot write' do
    user = users(:user_two)
    _token, secret = issue(user:)
    user.scanlator_users.destroy_all
    found = ApiToken.authenticate(secret)

    assert_not found.permits?('chapters:write')
    assert_not found.permits?('chapters:publish')
    assert_not found.permits?('images:write')
  end

  test 'an admin without a team cannot create a token' do
    user = users(:user_one)
    user.scanlator_users.destroy_all

    error = assert_raises(ActiveRecord::RecordInvalid) { issue(user:) }

    assert_includes error.record.errors[:base], I18n.t('activerecord.errors.models.api_token.attributes.base.no_team')
  end

  test 'a user can keep only five active tokens' do
    user = users(:user_two)
    5.times { |index| issue(user:, name: "Ключ #{index}") }
    user.api_tokens.last.revoke!

    assert_difference -> { user.api_tokens.active.count }, 1 do
      issue(user:, name: 'Після відкликання')
    end

    error = assert_raises(ActiveRecord::RecordInvalid) { issue(user:, name: 'Зайвий') }

    assert_includes error.record.errors[:base], I18n.t('activerecord.errors.models.api_token.attributes.base.too_many')
  end

  private

  def issue(user: users(:user_two), name: 'Claude')
    token = ApiToken.issue!(user:, name:, scopes: ApiToken::DEFAULT_SCOPES)
    [token, token.secret]
  end
end
