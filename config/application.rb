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

    Rails.logger.info "MIDDLEWARE_DEBUG: Request started - Path: #{request.path}, Method: #{request.request_method}, Request ID: #{request_id}"
    Rails.logger.info "MIDDLEWARE_DEBUG: Incoming cookies - Auth: #{auth_cookie.present?}, Remember: #{remember_cookie.present?}"

    if auth_cookie.present?
      Rails.logger.info "MIDDLEWARE_DEBUG: Auth cookie details - Length: #{auth_cookie.length}, First 20 chars: #{auth_cookie[0..19]}..."
    end

    # Call the next middleware
    status, headers, response = @app.call(env)

    # Log response cookies
    response_cookies = headers['Set-Cookie']
    if response_cookies
      begin
        # Handle both string and array responses safely
        cookies_array = Array(response_cookies)
        Rails.logger.info "MIDDLEWARE_DEBUG: Response cookies set - Count: #{cookies_array.length}"
        cookies_array.each do |cookie|
          if cookie.include?('_tanooki_session') || cookie.include?('remember_user_token')
            Rails.logger.info "MIDDLEWARE_DEBUG: Auth cookie in response: #{cookie.split(';').first}"
          end
        end
      rescue StandardError => e
        Rails.logger.warn "MIDDLEWARE_DEBUG: Error processing response cookies: #{e.message}"
      end
    else
      Rails.logger.info 'MIDDLEWARE_DEBUG: No cookies set in response'
    end

    Rails.logger.info "MIDDLEWARE_DEBUG: Request completed - Status: #{status}, Request ID: #{request_id}"

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
