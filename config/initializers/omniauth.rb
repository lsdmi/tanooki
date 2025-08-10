# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch('GOOGLE_CLIENT_ID', nil),
           ENV.fetch('GOOGLE_CLIENT_SECRET', nil),
           {
             scope: 'email,profile',
             prompt: 'select_account'
           }
end

# Set the default OmniAuth path prefix
OmniAuth.config.path_prefix = '/auth'

# Disable CSRF protection for OmniAuth
OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning = true
