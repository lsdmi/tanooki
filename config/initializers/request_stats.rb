# frozen_string_literal: true

unless Rails.env.test?
  ActiveSupport::Notifications.subscribe('process_action.action_controller') do |event|
    Analytics::RequestStats.default.add_event(event)
  end
  Rails.application.reloader.before_class_unload { Analytics::RequestStats.shutdown }
  at_exit { Analytics::RequestStats.shutdown }
end
