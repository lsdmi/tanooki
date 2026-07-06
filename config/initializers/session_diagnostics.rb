# frozen_string_literal: true

Warden::Manager.before_failure do |env, opts|
  SessionDiagnostics::Logger.log_auth_failure(ActionDispatch::Request.new(env), opts)
end
