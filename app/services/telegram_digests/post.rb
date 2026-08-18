# frozen_string_literal: true

module TelegramDigests
  # Dispatches a named weekly digest for CI / operator rake runs.
  class Post
    DIGESTS = {
      'youtube' => YoutubeVideos,
      'weekly_stats' => WeeklyStats,
      'fictions' => Fictions,
      'publications' => Publications
    }.freeze

    def self.call(digest)
      new(digest).call
    end

    def initialize(digest)
      @digest = digest.to_s
    end

    def call
      klass = DIGESTS[@digest]
      raise ArgumentError, "unknown digest=#{@digest.inspect} (want #{DIGESTS.keys.join(', ')})" unless klass

      klass.call
    end
  end
end
