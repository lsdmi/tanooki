# frozen_string_literal: true

# Warden logging for debugging authentication issues
Warden::Manager.after_authentication do |user, auth, opts|
  Rails.logger.info "[WARDEN_DEBUG] User authenticated successfully - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{auth.request.session.id}"
  Rails.logger.info "[WARDEN_DEBUG] Session keys after auth: #{auth.request.session.keys.join(', ')}"

  # Check for Warden authentication keys (Warden uses string keys, not symbol keys)
  warden_keys = auth.request.session.keys.select { |k| k.to_s.start_with?('warden.') }
  if warden_keys.any?
    Rails.logger.info "[WARDEN_DEBUG] ✅ Warden authentication keys found: #{warden_keys.join(', ')}"
    warden_keys.each do |key|
      Rails.logger.info "[WARDEN_DEBUG] #{key}: #{auth.request.session[key].inspect}"
    end
  else
    Rails.logger.warn '[WARDEN_DEBUG] ❌ No Warden authentication keys found after authentication'
  end
end

Warden::Manager.before_failure do |env, opts|
  Rails.logger.warn "[WARDEN_DEBUG] Authentication failure - Reason: #{opts[:message]}, Session ID: #{env['rack.session']&.id}"
  Rails.logger.warn "[WARDEN_DEBUG] Failure options: #{opts.inspect}"
end

Warden::Manager.before_logout do |user, auth, opts|
  Rails.logger.info "[WARDEN_DEBUG] User logging out - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{auth.request.session.id}"
end

Warden::Manager.after_set_user do |user, auth, opts|
  Rails.logger.info "[WARDEN_DEBUG] User set in session - ID: #{user&.id}, Email: #{user&.email}, Session ID: #{auth.request.session.id}"
  Rails.logger.info "[WARDEN_DEBUG] Session keys after set_user: #{auth.request.session.keys.join(', ')}"

  # Check for Warden authentication keys (Warden uses string keys, not symbol keys)
  warden_keys = auth.request.session.keys.select { |k| k.to_s.start_with?('warden.') }
  if warden_keys.any?
    Rails.logger.info "[WARDEN_DEBUG] ✅ Warden authentication keys found: #{warden_keys.join(', ')}"
    warden_keys.each do |key|
      Rails.logger.info "[WARDEN_DEBUG] #{key}: #{auth.request.session[key].inspect}"
    end
  else
    Rails.logger.warn '[WARDEN_DEBUG] ❌ No Warden authentication keys found after set_user'
  end
end

Rails.logger.info "[WARDEN_DEBUG] Warden logging initializer loaded at #{Time.current}"
