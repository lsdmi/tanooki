# frozen_string_literal: true

# Base class for Active Job workers; configures default retry/discard behavior.
class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError
end
