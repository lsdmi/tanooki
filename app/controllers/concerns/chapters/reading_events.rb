# frozen_string_literal: true

module Chapters
  # Maps chapters#record_progress payloads to reading services: "engaged" moves the resume cursor,
  # "completed" adds the chapter to the sparse read set. Unknown events and sources map to nil.
  module ReadingEvents
    extend ActiveSupport::Concern

    private

    # 200 when something was written, 204 for a no-op, 422 for an unknown event or source.
    def record_reading_event
      reading_event = build_reading_event
      return :unprocessable_content unless reading_event

      reading_event.call ? :ok : :no_content
    end

    def build_reading_event
      case params[:event]
      when 'engaged'
        Reading::RecordProgress.new(chapter: @chapter, user: current_user)
      when 'completed'
        source = params[:source].to_s
        return unless ReadingChapterRead::EVENT_SOURCES.include?(source)

        Reading::RecordCompletion.new(chapter: @chapter, user: current_user, source:)
      end
    end
  end
end
