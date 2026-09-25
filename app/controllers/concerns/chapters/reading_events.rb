# frozen_string_literal: true

module Chapters
  # Maps chapters#record_progress payloads to reading services: "engaged" moves the resume cursor,
  # "position" updates where the reader is inside the resume chapter, "completed" adds the chapter to the
  # sparse read set. Unknown events and sources, and a position without a usable locator, map to nil.
  module ReadingEvents
    extend ActiveSupport::Concern

    LOCATOR_KEYS = %i[quote block_index percent digest].freeze

    private

    # 200 when something was written, 204 for a no-op, 422 for an unknown or malformed event.
    def record_reading_event
      reading_event = build_reading_event
      return :unprocessable_content unless reading_event

      reading_event.call ? :ok : :no_content
    end

    def build_reading_event
      case params[:event]
      when 'engaged'
        Reading::RecordProgress.new(chapter: @chapter, user: current_user, locator: reading_locator)
      when 'position'
        build_position_event
      when 'completed'
        source = params[:source].to_s
        return unless ReadingChapterRead::EVENT_SOURCES.include?(source)

        Reading::RecordCompletion.new(chapter: @chapter, user: current_user, source:)
      end
    end

    def build_position_event
      locator = reading_locator
      Reading::RecordPosition.new(chapter: @chapter, user: current_user, locator:) if locator
    end

    def reading_locator
      raw = params[:locator]
      Reading::ResumeLocator.parse(raw.permit(*LOCATOR_KEYS)) if raw.is_a?(ActionController::Parameters)
    end
  end
end
