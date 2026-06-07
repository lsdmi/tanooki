# frozen_string_literal: true

module Reading
  # Opens the chapter reader ad drawer every 4th chapter view in the session (1, 5, 9, …).
  # Suppressed entirely when +User#ads_free?+ is true (future Premium / No-Ads tier).
  class AdDrawerSession
    INTERVAL = 4

    def self.call(chapter_id:, session_state:)
      new(chapter_id:, session_state:).call
    end

    def initialize(chapter_id:, session_state:)
      @chapter_id = chapter_id.to_s
      @state = (session_state || {}).stringify_keys
    end

    def call
      return [@state, false] if @state['last_chapter_id'] == @chapter_id

      views = @state.fetch('chapter_views', 0).to_i + 1
      should_open = ((views - 1) % INTERVAL).zero?

      @state['chapter_views'] = views
      @state['last_chapter_id'] = @chapter_id

      [@state, should_open]
    end
  end
end
