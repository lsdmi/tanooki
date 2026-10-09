# frozen_string_literal: true

require 'test_helper'

class OauthRedirectsTest < ActiveSupport::TestCase
  test 'the public chat hosts are allowed over https' do
    assert Oauth::Redirects.allowed?('https://chatgpt.com/connector/oauth/callback')
    assert Oauth::Redirects.allowed?('https://chat.openai.com/a/callback')
    assert Oauth::Redirects.allowed?('https://claude.ai/api/mcp/auth_callback')
  end

  test 'lookalikes and plain http are refused' do
    assert_not Oauth::Redirects.allowed?('https://chatgpt.com.evil/callback')
    assert_not Oauth::Redirects.allowed?('http://chatgpt.com/callback')
    assert_not Oauth::Redirects.allowed?('https://user:pass@claude.com/callback')
  end

  test 'muse may return to its own callback' do
    assert Oauth::Redirects.allowed?('https://agent.meta.ai/api/hatch/oauth/callback')
    assert_not Oauth::Redirects.allowed?('https://agent.meta.ai.evil/callback')
    assert_not Oauth::Redirects.allowed?('http://agent.meta.ai/callback')
  end

  test 'loopback is allowed only for local requests' do
    assert Oauth::Redirects.allowed?('http://localhost:6274/callback')
    assert Oauth::Redirects.allowed?('http://127.0.0.1/callback')
    assert_not Oauth::Redirects.allowed?('https://localhost/callback')
  end
end
