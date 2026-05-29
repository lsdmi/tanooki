# frozen_string_literal: true

require 'google/apis/youtube_v3'

# Retry policy for YouTube Data API jobs.
module YoutubeApiJob
  extend ActiveSupport::Concern
  include ExternalApiResilience

  included do
    retry_on Google::Apis::RateLimitError,
             Google::Apis::ServerError,
             Google::Apis::TransmissionError,
             wait: :polynomially_longer,
             attempts: 5
    discard_on Google::Apis::ClientError
  end
end
