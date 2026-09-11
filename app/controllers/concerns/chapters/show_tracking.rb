# frozen_string_literal: true

module Chapters
  # Side effects for chapters#show that must not run on Turbo prefetch cache fills.
  module ShowTracking
    extend ActiveSupport::Concern

    private

    def track_reading_progress
      return if turbo_prefetch_request?

      Reading::RecordProgress.new(chapter: @chapter, user: current_user).call
    end

    # Every-4th-chapter session cadence gates only the auto-opening ad drawer, not top/bottom reader slots.
    def assign_reader_ad_drawer_session
      @reader_ad_drawer_open = false
      return if turbo_prefetch_request?
      return unless chapter_reader_ad_drawer_live?

      state, @reader_ad_drawer_open = Reading::AdDrawerSession.call(
        chapter_id: @chapter.id,
        session_state: session[:reader_ad_drawer]
      )
      session[:reader_ad_drawer] = state
    end
  end
end
