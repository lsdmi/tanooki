# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Cookie debugging middleware
class CookieDebugMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    request_id = env['action_dispatch.request_id']

    # Log incoming cookies
    auth_cookie = request.cookies['_tanooki_session']
    remember_cookie = request.cookies['remember_user_token']

    Rails.logger.info "MIDDLEWARE_ENTRY: Request started - Path: #{request.path}, Method: #{request.request_method}, Request ID: #{request_id}"
    Rails.logger.info "MIDDLEWARE_ENTRY: Incoming cookies - Auth: #{auth_cookie.present?}, Remember: #{remember_cookie.present?}"

    if auth_cookie.present?
      Rails.logger.info "MIDDLEWARE_ENTRY: Auth cookie details - Length: #{auth_cookie.length}, First 20 chars: #{auth_cookie[0..19]}..."

      # Check for suspicious short cookies
      if auth_cookie.length <= 50
        Rails.logger.warn "MIDDLEWARE_ENTRY: ⚠️ SUSPICIOUS SHORT COOKIE - Length: #{auth_cookie.length} (normal cookies are 900+ chars)"
        Rails.logger.warn "MIDDLEWARE_ENTRY: Full cookie value: #{auth_cookie}"
      end
    end

    # Call the next middleware
    status, headers, response = @app.call(env)

    # Log response cookies with detailed analysis
    response_cookies = headers['Set-Cookie']
    if response_cookies
      begin
        # Handle both string and array responses safely
        cookies_array = Array(response_cookies)
        Rails.logger.info "MIDDLEWARE_EXIT: Response cookies set - Count: #{cookies_array.length}, Request ID: #{request_id}"

        cookies_array.each do |cookie|
          next unless cookie.include?('_tanooki_session') || cookie.include?('remember_user_token')

          cookie_name = cookie.split('=').first
          cookie_value = cookie.split('=').last&.split(';')&.first

          Rails.logger.info "MIDDLEWARE_EXIT: Auth cookie in response: #{cookie_name}=#{cookie_value&.length} chars"

          # Check for suspicious short response cookies
          if cookie_value && cookie_value.length <= 50
            Rails.logger.warn "MIDDLEWARE_EXIT: ⚠️ SUSPICIOUS SHORT RESPONSE COOKIE - Length: #{cookie_value.length}"
            Rails.logger.warn "MIDDLEWARE_EXIT: Full response cookie: #{cookie}"
          end

          # Try to decrypt and check session data
          next unless cookie_name == '_tanooki_session' && cookie_value

          begin
            decoded = Rails.application.message_verifier('_tanooki_session').verify(cookie_value)
            warden_keys = decoded.keys.select { |k| k.to_s.start_with?('warden.') }
            debug_user_id = decoded['debug_user_id']

            if warden_keys.any?
              Rails.logger.info "MIDDLEWARE_EXIT: ✅ Response cookie has Warden keys: #{warden_keys.join(', ')}"
            else
              Rails.logger.warn "MIDDLEWARE_EXIT: ❌ Response cookie has no Warden keys - keys: #{decoded.keys.join(', ')}"
            end

            Rails.logger.info "MIDDLEWARE_EXIT: Debug User ID in response cookie: #{debug_user_id}" if debug_user_id
          rescue StandardError => e
            Rails.logger.error "MIDDLEWARE_EXIT: 🚨 Response cookie decryption failed: #{e.message}"
            Rails.logger.error "MIDDLEWARE_EXIT: Failed cookie value: #{cookie_value}"
          end
        end
      rescue StandardError => e
        Rails.logger.warn "MIDDLEWARE_EXIT: Error processing response cookies: #{e.message}"
      end
    else
      Rails.logger.info "MIDDLEWARE_EXIT: No cookies set in response - Request ID: #{request_id}"
    end

    # Log session state from the environment if available
    if env['rack.session']
      session_id = env['rack.session'].id
      session_keys = env['rack.session'].keys
      warden_keys = session_keys.select { |k| k.to_s.start_with?('warden.') }
      debug_user_id = env['rack.session']['debug_user_id']

      Rails.logger.info "MIDDLEWARE_EXIT: Final session state - Session ID: #{session_id}, Keys: #{session_keys.join(', ')}"

      if warden_keys.any?
        Rails.logger.info "MIDDLEWARE_EXIT: ✅ Final Warden keys: #{warden_keys.join(', ')}"
      else
        Rails.logger.warn 'MIDDLEWARE_EXIT: ❌ No Warden keys in final session state'
      end

      Rails.logger.info "MIDDLEWARE_EXIT: Debug User ID in final session: #{debug_user_id}" if debug_user_id

      # NEW CHECK: Detect session corruption in middleware
      if debug_user_id && warden_keys.empty?
        Rails.logger.error "MIDDLEWARE_EXIT: 🚨 SESSION CORRUPTION DETECTED - Debug User ID: #{debug_user_id} but NO Warden keys! Session ID: #{session_id}"
        Rails.logger.error 'MIDDLEWARE_EXIT: This indicates the session was corrupted during middleware processing'
        Rails.logger.error "MIDDLEWARE_EXIT: Session keys present: #{session_keys.join(', ')}"

        # Check if this is a response cookie issue
        if headers['Set-Cookie']
          Rails.logger.error 'MIDDLEWARE_EXIT: 🔍 MIDDLEWARE CORRUPTION ANALYSIS:'
          Rails.logger.error 'MIDDLEWARE_EXIT: - Session has user_id but no Warden keys'
          Rails.logger.error 'MIDDLEWARE_EXIT: - Possible causes:'
          Rails.logger.error 'MIDDLEWARE_EXIT:   * Warden keys were lost during middleware processing'
          Rails.logger.error 'MIDDLEWARE_EXIT:   * Session serialization error in middleware'
          Rails.logger.error 'MIDDLEWARE_EXIT:   * Cookie encoding/decoding issue'
          Rails.logger.error 'MIDDLEWARE_EXIT:   * Session store corruption'
        end
      end
    end

    Rails.logger.info "MIDDLEWARE_EXIT: Request completed - Status: #{status}, Request ID: #{request_id}"

    [status, headers, response]
  end
end

module Tanooki
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.i18n.default_locale = :uk
    config.i18n.available_locales = %i[uk en]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Europe/Kiev'
    # config.eager_load_paths << Rails.root.join('extras')

    config.active_storage.variant_processor = :mini_magick
    config.autoload_paths += %W[#{config.root}/app/services]
    config.autoload_paths += %W[#{config.root}/app/query]
    config.autoload_paths += %W[#{config.root}/app/forms]

    # Add cookie debugging middleware after Warden to avoid interfering with authentication
    config.middleware.insert_after Warden::Manager, CookieDebugMiddleware
  end
end

Rails.configuration.after_initialize do
  ActionText::RichText.class_eval do
    acts_as_paranoid

    default_scope -> { where(deleted_at: nil) }
  end

  ActiveStorage::Attachment.class_eval do
    acts_as_paranoid

    default_scope -> { where(deleted_at: nil) }
  end

  ActiveStorage::Blob.class_eval do
    acts_as_paranoid

    default_scope -> { where(deleted_at: nil) }
  end
end
