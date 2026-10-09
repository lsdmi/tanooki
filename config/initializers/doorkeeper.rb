# frozen_string_literal: true

# OAuth for ChatGPT, claude.ai, and Muse. Public clients, PKCE, and a consent screen.
# Dynamic registration is Oauth::RegistrationsController; Doorkeeper 5.9 has none.
Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    current_user || authenticate_user!
  end

  base_controller 'ApplicationController'

  default_scopes 'chapters:read'
  optional_scopes 'chapters:write', 'chapters:publish', 'images:write', 'offline_access'
  enforce_configured_scopes

  grant_flows %w[authorization_code refresh_token]
  access_token_expires_in 2.hours
  use_refresh_token
  force_pkce
  hash_token_secrets
  revoke_previous_authorization_code_token
  allow_token_introspection false

  force_ssl_in_redirect_uri { |uri| %w[localhost 127.0.0.1].exclude?(uri.host) }

  skip_authorization { false }
end
