# frozen_string_literal: true

# Base class for Active Job workers; configures default retry/discard behavior.
class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 3
  retry_on SolidQueue::Processes::ProcessPrunedError, wait: 30.seconds, attempts: 5
  retry_on Faraday::SSLError, Faraday::ConnectionFailed, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError
end
