# frozen_string_literal: true

# Warden logging for debugging authentication issues
Warden::Manager.after_authentication do |user, auth, opts|
  session_id = auth.request.session.id

  # Add debug_user_id to session for tracking
  if user&.id
    auth.request.session[:debug_user_id] = user.id
    Rails.logger.info "[WARDEN_ENTRY] Added debug_user_id to session: #{user.id} - Session ID: #{session_id}"
  end

  Rails.logger.info "[WARDEN_ENTRY] User authenticated successfully - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{session_id}"
  Rails.logger.info "[WARDEN_ENTRY] User object details - Class: #{user&.class}, Inspect: #{user&.inspect}"
  Rails.logger.info "[WARDEN_ENTRY] Session keys after auth: #{auth.request.session.keys.join(', ')}"

  # Check for Warden authentication keys (Warden uses string keys, not symbol keys)
  warden_keys = auth.request.session.keys.select { |k| k.to_s.start_with?('warden.') }
  if warden_keys.any?
    Rails.logger.info "[WARDEN_ENTRY] ✅ Warden authentication keys found: #{warden_keys.join(', ')}"
    warden_keys.each do |key|
      warden_value = auth.request.session[key]
      Rails.logger.info "[WARDEN_ENTRY] #{key}: #{warden_value.inspect}"

      # If this is a user object, show more details
      if warden_value.respond_to?(:id) && warden_value.respond_to?(:email)
        Rails.logger.info "[WARDEN_ENTRY] Warden user object - ID: #{warden_value.id}, Email: #{warden_value.email}, Class: #{warden_value.class}"
      end
    end
  else
    Rails.logger.warn '[WARDEN_ENTRY] ❌ No Warden authentication keys found after authentication'
  end
end

Warden::Manager.before_failure do |env, opts|
  session_id = env['rack.session']&.id
  debug_user_id = env['rack.session']&.[]('debug_user_id')

  Rails.logger.warn "[WARDEN_FAILURE] Authentication failure - Reason: #{opts[:message]}, Session ID: #{session_id}, Debug User ID: #{debug_user_id}"
  Rails.logger.warn "[WARDEN_FAILURE] Failure options: #{opts.inspect}"

  # Log session state during failure
  if env['rack.session']
    Rails.logger.warn "[WARDEN_FAILURE] Session keys during failure: #{env['rack.session'].keys.join(', ')}"
    warden_keys = env['rack.session'].keys.select { |k| k.to_s.start_with?('warden.') }
    if warden_keys.any?
      Rails.logger.warn "[WARDEN_FAILURE] Warden keys during failure: #{warden_keys.join(', ')}"
    else
      Rails.logger.warn '[WARDEN_FAILURE] No Warden keys during failure'
    end
  end
end

Warden::Manager.before_logout do |user, auth, opts|
  session_id = auth.request.session.id
  debug_user_id = auth.request.session[:debug_user_id]

  Rails.logger.info "[WARDEN_LOGOUT] User logging out - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{session_id}, Debug User ID: #{debug_user_id}"

  # Log session state before logout
  Rails.logger.info "[WARDEN_LOGOUT] Session keys before logout: #{auth.request.session.keys.join(', ')}"
  warden_keys = auth.request.session.keys.select { |k| k.to_s.start_with?('warden.') }
  if warden_keys.any?
    Rails.logger.info "[WARDEN_LOGOUT] Warden keys before logout: #{warden_keys.join(', ')}"
  else
    Rails.logger.warn '[WARDEN_LOGOUT] No Warden keys before logout'
  end
end

Warden::Manager.after_set_user do |user, auth, opts|
  session_id = auth.request.session.id

  # Add debug_user_id to session for tracking
  if user&.id
    auth.request.session[:debug_user_id] = user.id
    Rails.logger.info "[WARDEN_SET_USER] Added debug_user_id to session: #{user.id} - Session ID: #{session_id}"
  end

  Rails.logger.info "[WARDEN_SET_USER] User set in session - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{session_id}"
  Rails.logger.info "[WARDEN_SET_USER] User object details - Class: #{user&.class}, Inspect: #{user&.inspect}"
  Rails.logger.info "[WARDEN_SET_USER] Session keys after set_user: #{auth.request.session.keys.join(', ')}"

  # Check for Warden authentication keys (Warden uses string keys, not symbol keys)
  warden_keys = auth.request.session.keys.select { |k| k.to_s.start_with?('warden.') }
  if warden_keys.any?
    Rails.logger.info "[WARDEN_SET_USER] ✅ Warden authentication keys found: #{warden_keys.join(', ')}"
    warden_keys.each do |key|
      warden_value = auth.request.session[key]
      Rails.logger.info "[WARDEN_SET_USER] #{key}: #{warden_value.inspect}"

      # If this is a user object, show more details
      if warden_value.respond_to?(:id) && warden_value.respond_to?(:email)
        Rails.logger.info "[WARDEN_SET_USER] Warden user object - ID: #{warden_value.id}, Email: #{warden_value.email}, Class: #{warden_value.class}"
      end
    end
  else
    Rails.logger.warn '[WARDEN_SET_USER] ❌ No Warden authentication keys found after set_user'
  end
end

# Add exit hooks for session state tracking
Warden::Manager.after_authentication do |user, auth, opts|
  session_id = auth.request.session.id
  debug_user_id = auth.request.session[:debug_user_id]

  Rails.logger.info "[WARDEN_EXIT] Authentication completed - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{session_id}, Debug User ID: #{debug_user_id}"

  # Check final session state
  warden_keys = auth.request.session.keys.select { |k| k.to_s.start_with?('warden.') }
  if warden_keys.any?
    Rails.logger.info "[WARDEN_EXIT] ✅ Final Warden keys: #{warden_keys.join(', ')}"
  else
    Rails.logger.error '[WARDEN_EXIT] 🚨 CRITICAL - No Warden keys after authentication completion!'
  end
end

Warden::Manager.after_set_user do |user, auth, opts|
  session_id = auth.request.session.id
  debug_user_id = auth.request.session[:debug_user_id]

  Rails.logger.info "[WARDEN_EXIT] Set user completed - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{session_id}, Debug User ID: #{debug_user_id}"

  # Check final session state
  warden_keys = auth.request.session.keys.select { |k| k.to_s.start_with?('warden.') }
  if warden_keys.any?
    Rails.logger.info "[WARDEN_EXIT] ✅ Final Warden keys after set_user: #{warden_keys.join(', ')}"
  else
    Rails.logger.error '[WARDEN_EXIT] 🚨 CRITICAL - No Warden keys after set_user completion!'
  end
end

Rails.logger.info "[WARDEN_DEBUG] Warden logging initializer loaded at #{Time.current}"
