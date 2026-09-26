# frozen_string_literal: true

module Chapters
  # In-chapter resume on the chapter the resume cursor is on. A ?resume=1 visit («Читати далі») restores straight
  # away; any other visit (list, prev/next, a link) offers it in a banner instead of jumping, and holds position
  # capture until the reader answers so opening the chapter can't overwrite the saved place.
  module ReaderResumeHelper
    BANNER_MIN_PERCENT = 1

    def reader_resume_locator(chapter)
      return unless user_signed_in?

      progress = ReadingProgress.find_by(user: current_user, fiction_id: chapter.fiction_id, chapter_id: chapter.id)
      locator = Reading::ResumeLocator.from_progress(progress)
      locator if locator && (reader_resume_auto? || banner_worthy?(locator))
    end

    def reader_resume_auto?
      params[:resume] == '1'
    end

    def reader_resume_data(locator)
      values = { quote: locator.quote, block_index: locator.block_index, percent: locator.percent,
                 digest: locator.digest, auto: reader_resume_auto? }
      data = values.compact.transform_keys { :"reading_resume_#{it}_value" }
      reader_resume_auto? ? data : data.merge(reading_progress_hold_value: true)
    end

    private

    # Right at the start or already finished: nothing to come back to.
    def banner_worthy?(locator)
      locator.percent >= BANNER_MIN_PERCENT && locator.percent < Reading::ContinueTarget::FINISHED_PERCENT
    end
  end
end
