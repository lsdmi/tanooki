# frozen_string_literal: true

# Web server only: the watcher must live outside the worker it watches, and consoles or rake tasks need no thread.
if Rails.env.production? && defined?(Rails::Server)
  Rails.application.config.after_initialize { Workers::LivenessWatch.default.start }
  at_exit { Workers::LivenessWatch.shutdown }
end
