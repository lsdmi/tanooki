# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Warden hooks for authentication events
  Warden::Manager.after_set_user do |user, auth, opts|
    Rails.logger.info "SESSION_DEBUG: User authenticated - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{auth.request.session.id}, Time: #{Time.current}"
  end

  Warden::Manager.before_logout do |user, auth, opts|
    Rails.logger.info "SESSION_DEBUG: User logging out - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{auth.request.session.id}, Time: #{Time.current}"
  end

  Warden::Manager.before_failure do |env, opts|
    Rails.logger.warn "SESSION_DEBUG: Auth failure - Session ID: #{env['rack.session']&.id}, Reason: #{opts[:message]}, Time: #{Time.current}"
  end

  # Controller-level logging for session/cookie state
  ActionController::Base.class_eval do
    before_action :log_cookie_and_session_debug

    private

    def log_cookie_and_session_debug
      session_id = session.id
      request_id = request.request_id
      auth_cookie = cookies['_tanooki_session']
      remember_cookie = cookies['remember_user_token']

      Rails.logger.info "COOKIE_DEBUG: [1] Cookie check - Session ID: #{session_id}, Request ID: #{request_id}"
      Rails.logger.info "COOKIE_DEBUG: [1] Auth cookie present: #{auth_cookie.present?}, Remember cookie present: #{remember_cookie.present?}"
      Rails.logger.info "COOKIE_DEBUG: [1] Auth cookie length: #{auth_cookie&.length}" if auth_cookie.present?
      if remember_cookie.present?
        Rails.logger.info "COOKIE_DEBUG: [1] Remember cookie length: #{remember_cookie&.length}"
      end

      # 2. Try to decrypt session cookie
      begin
        if auth_cookie.present?
          decoded = cookies.encrypted['_tanooki_session']
          if decoded.is_a?(Hash)
            Rails.logger.info "COOKIE_DEBUG: [2] Cookie decryption successful - keys: #{decoded&.keys&.join(', ')}"
          end
        else
          Rails.logger.info 'COOKIE_DEBUG: [2] No auth cookie to decrypt'
        end
      rescue StandardError => e
        Rails.logger.error "COOKIE_DEBUG: [2] Cookie decryption failed: #{e.class}: #{e.message}"
      end

      # 3. Session data after decryption
      Rails.logger.info "COOKIE_DEBUG: [3] Session keys: #{session.keys.join(', ')}"

      # Check for Warden authentication keys (Warden uses string keys, not symbol keys)
      warden_keys = session.keys.select { |k| k.to_s.start_with?('warden.') }
      if warden_keys.any?
        Rails.logger.info "COOKIE_DEBUG: [3] ✅ Found Warden authentication keys: #{warden_keys.join(', ')}"
        warden_keys.each do |key|
          Rails.logger.info "COOKIE_DEBUG: [3] #{key}: #{session[key].inspect}"
        end
      else
        Rails.logger.info 'COOKIE_DEBUG: [3] ❌ No Warden authentication keys found'

        # Distinguish between guest user and broken session
        session_keys = session.keys
        if session_keys.empty?
          Rails.logger.warn 'COOKIE_DEBUG: [3] 🚨 BROKEN SESSION - Empty session keys (should have at least session_id)'
        elsif session_keys.include?('pokemon_catch_last_seen') || session_keys.include?('pokemon_guest_caught') || session_keys.include?('viewed')
          Rails.logger.info 'COOKIE_DEBUG: [3] 👤 GUEST USER - Has guest features (pokemon_catch_last_seen, viewed, etc.)'
        elsif session_keys.include?('session_id') && session_keys.length == 1
          Rails.logger.info 'COOKIE_DEBUG: [3] 🆕 NEW USER - Only has session_id, no guest features yet'
        else
          Rails.logger.warn "COOKIE_DEBUG: [3] ❓ UNKNOWN PATTERN - Session keys: #{session_keys.join(', ')}"
        end
      end

      # NOTE: session[:warden] is typically nil - Warden uses string keys like "warden.user.user.key"
      Rails.logger.info "COOKIE_DEBUG: [3] Session[:warden] (symbol key): #{session[:warden].inspect}"

      # Check if user is actually authenticated
      if respond_to?(:user_signed_in?) && user_signed_in?
        Rails.logger.info "COOKIE_DEBUG: [3] ✅ User IS authenticated - ID: #{current_user&.id}, Email: #{current_user&.email}"
        Rails.logger.info "COOKIE_DEBUG: [3] Warden keys present: #{warden_keys.any? ? 'Yes' : 'No'}"
      elsif respond_to?(:user_signed_in?) && !user_signed_in? && auth_cookie.present?
        Rails.logger.info 'COOKIE_DEBUG: [3] ❌ User NOT authenticated despite cookie'
        Rails.logger.info "COOKIE_DEBUG: [3] Warden keys present: #{warden_keys.any? ? 'Yes' : 'No'}"
      end

      # 4. User in session/devise
      warden_user = begin
        request.env['warden']&.user
      rescue StandardError
        nil
      end
      Rails.logger.info "COOKIE_DEBUG: [4] Warden user: #{warden_user&.id if warden_user}" if warden_user
      Rails.logger.info "COOKIE_DEBUG: [4] user_signed_in?: #{respond_to?(:user_signed_in?) ? user_signed_in? : 'n/a'}, current_user: #{if respond_to?(:current_user)
                                                                                                                                          current_user&.id
                                                                                                                                        end}"

      # 5. Check Warden session data serialization
      if warden_keys.any?
        begin
          # Try to serialize the Warden session data to see if there are any issues
          warden_keys.each do |key|
            Marshal.dump(session[key])
          end
          Rails.logger.info 'COOKIE_DEBUG: [5] Warden session data serialization: OK'
        rescue StandardError => e
          Rails.logger.error "COOKIE_DEBUG: [5] Warden session data serialization error: #{e.message}"
        end
      else
        Rails.logger.info 'COOKIE_DEBUG: [5] No Warden session data to serialize'
      end

      # 6. Post-middleware authentication state
      return unless respond_to?(:user_signed_in?) && !user_signed_in? && auth_cookie.present?

      # Only warn for actual problems, not normal guest users
      session_keys = session.keys
      if session_keys.empty?
        Rails.logger.warn 'COOKIE_DEBUG: [6] 🚨 WARNING - BROKEN SESSION! Cookie present but session is empty!'
      elsif session_keys.include?('pokemon_catch_last_seen') || session_keys.include?('pokemon_guest_caught')
        Rails.logger.info 'COOKIE_DEBUG: [6] ℹ️ Normal guest user - no authentication needed'
      else
        Rails.logger.warn 'COOKIE_DEBUG: [6] WARNING - Cookie present but user not authenticated!'
        Rails.logger.warn 'COOKIE_DEBUG: [6] Possible causes: Invalid cookie, Expired session, Middleware issue'
      end
    end
  end

  Rails.logger.info "SESSION_DEBUG: Initializer loaded at #{Time.current}"
end
