# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Warden hooks for authentication events
  Warden::Manager.after_set_user do |user, auth, opts|
    session_id = auth.request.session.id
    Rails.logger.info "SESSION_DEBUG: User authenticated - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{session_id}, Time: #{Time.current}"
  end

  Warden::Manager.before_logout do |user, auth, opts|
    session_id = auth.request.session.id
    Rails.logger.info "SESSION_DEBUG: User logging out - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{session_id}, Time: #{Time.current}"
  end

  Warden::Manager.before_failure do |env, opts|
    session_id = env['rack.session']&.id
    Rails.logger.warn "SESSION_DEBUG: Auth failure - Session ID: #{session_id}, Reason: #{opts[:message]}, Time: #{Time.current}"
  end

  # Controller-level logging for session/cookie state
  ActionController::Base.class_eval do
    before_action :log_cookie_and_session_debug
    after_action :log_session_exit_debug

    private

    def log_cookie_and_session_debug
      session_id = session.id
      request_id = request.request_id
      auth_cookie = cookies['_tanooki_session']
      remember_cookie = cookies['remember_user_token']

      Rails.logger.info "COOKIE_ENTRY: [1] Cookie check - Session ID: #{session_id}, Request ID: #{request_id}"
      Rails.logger.info "COOKIE_ENTRY: [1] Auth cookie present: #{auth_cookie.present?}, Remember cookie present: #{remember_cookie.present?}"
      Rails.logger.info "COOKIE_ENTRY: [1] Auth cookie length: #{auth_cookie&.length}" if auth_cookie.present?
      if remember_cookie.present?
        Rails.logger.info "COOKIE_ENTRY: [1] Remember cookie length: #{remember_cookie&.length}"
      end

      # 2. Try to decrypt session cookie
      begin
        if auth_cookie.present?
          # Log cookie details for investigation
          Rails.logger.info "COOKIE_ENTRY: [2] Cookie analysis - Length: #{auth_cookie.length}, First 10 chars: #{auth_cookie[0..9]}, Last 10 chars: #{auth_cookie[-10..-1]}"

          # Check if it's a suspicious short cookie
          if auth_cookie.length <= 50
            Rails.logger.warn "COOKIE_ENTRY: [2] ⚠️ SUSPICIOUS SHORT COOKIE - Length: #{auth_cookie.length} (normal cookies are 900+ chars)"
            Rails.logger.warn "COOKIE_ENTRY: [2] Full cookie value: #{auth_cookie}"
          end

          decoded = cookies.encrypted['_tanooki_session']
          if decoded.is_a?(Hash)
            Rails.logger.info "COOKIE_ENTRY: [2] Cookie decryption successful - keys: #{decoded&.keys&.join(', ')}"
          elsif decoded.nil?
            Rails.logger.warn 'COOKIE_ENTRY: [2] Cookie decryption returned nil - cookie might be corrupted'
          else
            Rails.logger.warn "COOKIE_ENTRY: [2] Cookie decryption returned unexpected type: #{decoded.class}"
          end
        else
          Rails.logger.info 'COOKIE_ENTRY: [2] No auth cookie to decrypt'
        end
      rescue StandardError => e
        Rails.logger.error "COOKIE_ENTRY: [2] Cookie decryption failed: #{e.class}: #{e.message}"
        Rails.logger.error "COOKIE_ENTRY: [2] Failed cookie value: #{auth_cookie}"
      end

      # 3. Session data after decryption
      Rails.logger.info "COOKIE_ENTRY: [3] Session keys: #{session.keys.join(', ')}"

      # Check for Warden authentication keys (Warden uses string keys, not symbol keys)
      warden_keys = session.keys.select { |k| k.to_s.start_with?('warden.') }
      if warden_keys.any?
        Rails.logger.info "COOKIE_ENTRY: [3] ✅ Found Warden authentication keys: #{warden_keys.join(', ')}"
        warden_keys.each do |key|
          Rails.logger.info "COOKIE_ENTRY: [3] #{key}: #{session[key].inspect}"
        end
      else
        Rails.logger.info 'COOKIE_ENTRY: [3] ❌ No Warden authentication keys found'

        # Distinguish between guest user and broken session
        session_keys = session.keys
        if session_keys.empty?
          Rails.logger.warn 'COOKIE_ENTRY: [3] 🚨 BROKEN SESSION - Empty session keys (should have at least session_id)'
        elsif session_keys.include?('pokemon_catch_last_seen') || session_keys.include?('pokemon_guest_caught') || session_keys.include?('viewed')
          Rails.logger.info 'COOKIE_ENTRY: [3] 👤 GUEST USER - Has guest features (pokemon_catch_last_seen, viewed, etc.)'
        elsif session_keys.include?('session_id') && session_keys.length == 1
          Rails.logger.info 'COOKIE_ENTRY: [3] 🆕 NEW USER - Only has session_id, no guest features yet'
        else
          Rails.logger.warn "COOKIE_ENTRY: [3] ❓ UNKNOWN PATTERN - Session keys: #{session_keys.join(', ')}"
        end
      end

      # NOTE: session[:warden] is typically nil - Warden uses string keys like "warden.user.user.key"
      Rails.logger.info "COOKIE_ENTRY: [3] Session[:warden] (symbol key): #{session[:warden].inspect}"

      # Check if user is actually authenticated
      if respond_to?(:user_signed_in?) && user_signed_in?
        Rails.logger.info "COOKIE_ENTRY: [3] ✅ User IS authenticated - ID: #{current_user&.id}, Email: #{current_user&.email}"
        Rails.logger.info "COOKIE_ENTRY: [3] Warden keys present: #{warden_keys.any? ? 'Yes' : 'No'}"
      elsif respond_to?(:user_signed_in?) && !user_signed_in? && auth_cookie.present?
        Rails.logger.info 'COOKIE_ENTRY: [3] ❌ User NOT authenticated despite cookie'
        Rails.logger.info "COOKIE_ENTRY: [3] Warden keys present: #{warden_keys.any? ? 'Yes' : 'No'}"
      end

      # 4. User in session/devise
      warden_user = begin
        request.env['warden']&.user
      rescue StandardError
        nil
      end
      Rails.logger.info "COOKIE_ENTRY: [4] Warden user: #{warden_user&.id if warden_user}" if warden_user
      Rails.logger.info "COOKIE_ENTRY: [4] user_signed_in?: #{respond_to?(:user_signed_in?) ? user_signed_in? : 'n/a'}, current_user: #{if respond_to?(:current_user)
                                                                                                                                          current_user&.id
                                                                                                                                        end}"

      # 5. Check Warden session data serialization
      if warden_keys.any?
        begin
          # Try to serialize the Warden session data to see if there are any issues
          warden_keys.each do |key|
            Marshal.dump(session[key])
          end
          Rails.logger.info 'COOKIE_ENTRY: [5] Warden session data serialization: OK'
        rescue StandardError => e
          Rails.logger.error "COOKIE_ENTRY: [5] Warden session data serialization error: #{e.message}"
        end
      else
        Rails.logger.info 'COOKIE_ENTRY: [5] No Warden session data to serialize'
      end

      # 6. Post-middleware authentication state
      return unless respond_to?(:user_signed_in?) && !user_signed_in? && auth_cookie.present?

      # Only warn for actual problems, not normal guest users
      session_keys = session.keys
      if session_keys.empty?
        Rails.logger.warn 'COOKIE_ENTRY: [6] 🚨 WARNING - BROKEN SESSION! Cookie present but session is empty!'

        # Additional analysis for broken sessions
        if auth_cookie.length <= 50
          Rails.logger.warn 'COOKIE_ENTRY: [6] 🔍 BROKEN SESSION ANALYSIS:'
          Rails.logger.warn "COOKIE_ENTRY: [6] - Cookie length: #{auth_cookie.length} (suspiciously short)"
          Rails.logger.warn "COOKIE_ENTRY: [6] - Cookie value: #{auth_cookie}"
          Rails.logger.warn 'COOKIE_ENTRY: [6] - Possible causes:'
          Rails.logger.warn 'COOKIE_ENTRY: [6]   * Corrupted cookie during transmission'
          Rails.logger.warn 'COOKIE_ENTRY: [6]   * Browser cleared partial cookie data'
          Rails.logger.warn 'COOKIE_ENTRY: [6]   * Session store configuration issue'
          Rails.logger.warn 'COOKIE_ENTRY: [6]   * Secret key base changed'
        end
      elsif session_keys.include?('pokemon_catch_last_seen') || session_keys.include?('pokemon_guest_caught')
        Rails.logger.info 'COOKIE_ENTRY: [6] ℹ️ Normal guest user - no authentication needed'
      else
        Rails.logger.warn 'COOKIE_ENTRY: [6] WARNING - Cookie present but user not authenticated!'
        Rails.logger.warn 'COOKIE_ENTRY: [6] Possible causes: Invalid cookie, Expired session, Middleware issue'
      end
    end

    def log_session_exit_debug
      session_id = session.id
      request_id = request.request_id
      auth_cookie = cookies['_tanooki_session']
      remember_cookie = cookies['remember_user_token']

      Rails.logger.info "COOKIE_EXIT: [1] Exit check - Session ID: #{session_id}, Request ID: #{request_id}"
      Rails.logger.info "COOKIE_EXIT: [1] Auth cookie present: #{auth_cookie.present?}, Remember cookie present: #{remember_cookie.present?}"
      Rails.logger.info "COOKIE_EXIT: [1] Auth cookie length: #{auth_cookie&.length}" if auth_cookie.present?
      if remember_cookie.present?
        Rails.logger.info "COOKIE_EXIT: [1] Remember cookie length: #{remember_cookie&.length}"
      end

      # 2. Session data at exit
      Rails.logger.info "COOKIE_EXIT: [2] Session keys at exit: #{session.keys.join(', ')}"

      # Check for Warden authentication keys at exit
      warden_keys = session.keys.select { |k| k.to_s.start_with?('warden.') }
      if warden_keys.any?
        Rails.logger.info "COOKIE_EXIT: [2] ✅ Warden keys at exit: #{warden_keys.join(', ')}"
        warden_keys.each do |key|
          Rails.logger.info "COOKIE_EXIT: [2] #{key}: #{session[key].inspect}"
        end
      else
        Rails.logger.warn "COOKIE_EXIT: [2] ❌ No Warden keys at exit - Session ID: #{session_id}"
      end

      # 3. Authentication state at exit
      if respond_to?(:user_signed_in?) && user_signed_in?
        Rails.logger.info "COOKIE_EXIT: [3] ✅ User authenticated at exit - ID: #{current_user&.id}, Email: #{current_user&.email}"
        Rails.logger.info "COOKIE_EXIT: [3] Warden keys present: #{warden_keys.any? ? 'Yes' : 'No'}"
      elsif respond_to?(:user_signed_in?) && !user_signed_in? && auth_cookie.present?
        Rails.logger.warn "COOKIE_EXIT: [3] ❌ User NOT authenticated at exit despite cookie - Session ID: #{session_id}"
        Rails.logger.warn "COOKIE_EXIT: [3] Warden keys present: #{warden_keys.any? ? 'Yes' : 'No'}"
      end

      # 4. Check for session corruption at exit
      if session.keys.empty? && auth_cookie.present?
        Rails.logger.error "COOKIE_EXIT: [4] 🚨 CRITICAL - Session empty at exit but cookie present! Session ID: #{session_id}"
      elsif session.keys.empty? && respond_to?(:user_signed_in?) && user_signed_in?
        Rails.logger.error "COOKIE_EXIT: [4] 🚨 CRITICAL - User authenticated but session empty at exit! Session ID: #{session_id}"
      end

      # NEW CHECK: Detect session corruption (user_id present but no Warden keys)
      debug_user_id = session[:debug_user_id]
      if debug_user_id && warden_keys.empty?
        Rails.logger.error "COOKIE_EXIT: [4] 🚨 SESSION CORRUPTION DETECTED - Debug User ID: #{debug_user_id} but NO Warden keys! Session ID: #{session_id}"
        Rails.logger.error 'COOKIE_EXIT: [4] This indicates the session was corrupted during request processing'
        Rails.logger.error "COOKIE_EXIT: [4] Session keys present: #{session.keys.join(', ')}"
        Rails.logger.error "COOKIE_EXIT: [4] Auth cookie present: #{auth_cookie.present?}, Cookie length: #{auth_cookie&.length}"

        # Additional analysis for corrupted sessions
        if auth_cookie.present?
          Rails.logger.error 'COOKIE_EXIT: [4] 🔍 CORRUPTED SESSION ANALYSIS:'
          Rails.logger.error 'COOKIE_EXIT: [4] - User should be authenticated but Warden keys are missing'
          Rails.logger.error 'COOKIE_EXIT: [4] - Possible causes:'
          Rails.logger.error 'COOKIE_EXIT: [4]   * Warden keys were cleared during request processing'
          Rails.logger.error 'COOKIE_EXIT: [4]   * Session store corruption'
          Rails.logger.error 'COOKIE_EXIT: [4]   * Middleware interference'
          Rails.logger.error 'COOKIE_EXIT: [4]   * Cookie corruption during transmission'
          Rails.logger.error 'COOKIE_EXIT: [4]   * Session serialization/deserialization error'
        end
      end

      # 5. Check for suspicious short cookies at exit
      if auth_cookie.present? && auth_cookie.length <= 50
        Rails.logger.warn "COOKIE_EXIT: [5] ⚠️ SUSPICIOUS SHORT COOKIE AT EXIT - Length: #{auth_cookie.length}"
        Rails.logger.warn "COOKIE_EXIT: [5] Full cookie value: #{auth_cookie}"
      end

      # 6. Session state summary
      Rails.logger.info "COOKIE_EXIT: [6] Session state summary - Session ID: #{session_id}, Keys count: #{session.keys.length}, Warden keys: #{warden_keys.length}"
    end
  end

  Rails.logger.info "SESSION_DEBUG: Initializer loaded at #{Time.current}"
end
