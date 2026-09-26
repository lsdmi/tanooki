# frozen_string_literal: true

module Chapters
  # In-chapter restore for «Читати далі». Only a ?resume=1 visit of the chapter the resume cursor is on gets
  # the stored locator, so opening a chapter from the list or prev/next never jumps.
  module ReaderResumeHelper
    def reader_resume_locator(chapter)
      return unless user_signed_in? && params[:resume] == '1'

      progress = ReadingProgress.find_by(user: current_user, fiction_id: chapter.fiction_id, chapter_id: chapter.id)
      Reading::ResumeLocator.from_progress(progress)
    end

    def reader_resume_data(locator)
      values = { quote: locator.quote, block_index: locator.block_index, percent: locator.percent,
                 digest: locator.digest }
      values.compact.transform_keys { :"reading_resume_#{it}_value" }
    end
  end
end
