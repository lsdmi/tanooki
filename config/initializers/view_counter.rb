# frozen_string_literal: true

Rails.application.reloader.before_class_unload { Analytics::ViewCounter.shutdown }
at_exit { Analytics::ViewCounter.shutdown }
