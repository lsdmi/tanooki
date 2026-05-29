# frozen_string_literal: true

# Shared retry policy for transient network failures in outbound API jobs.
module ExternalApiResilience
  extend ActiveSupport::Concern

  TRANSIENT_NETWORK_ERRORS = [
    Errno::ECONNRESET,
    Errno::ETIMEDOUT,
    Net::OpenTimeout,
    Net::ReadTimeout,
    SocketError
  ].freeze

  included do
    retry_on(*TRANSIENT_NETWORK_ERRORS, wait: :polynomially_longer, attempts: 5)
  end
end
