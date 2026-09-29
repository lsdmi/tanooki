# frozen_string_literal: true

module Chapters
  # Mounts `reading-progress` on the chapter page. Guests also get what it needs to keep their reading record on
  # this device (fiction, chapter, this and the next chapter's paths), and `guest-resume` to restore from that record.
  module ReaderProgressHelper
    def reader_progress_controllers
      user_signed_in? ? 'reading-progress' : 'reading-progress guest-resume'
    end

    def reader_progress_data(chapter, next_chapter)
      data = { reading_progress_url_value: record_progress_chapter_path(chapter) }
      return data if user_signed_in?

      data.merge(reader_guest_progress_data(chapter, next_chapter), guest_resume_data(chapter))
    end

    private

    def reader_guest_progress_data(chapter, next_chapter)
      {
        reading_progress_guest_value: true,
        reading_progress_fiction_id_value: chapter.fiction_id,
        reading_progress_chapter_id_value: chapter.id,
        reading_progress_chapter_path_value: chapter_path(chapter),
        reading_progress_next_path_value: (chapter_path(next_chapter) if next_chapter)
      }.compact
    end

    # The banner label is filled in on the device, where the stored percent is known.
    def guest_resume_data(chapter)
      {
        guest_resume_fiction_id_value: chapter.fiction_id,
        guest_resume_chapter_id_value: chapter.id,
        guest_resume_label_value: t('chapters.reader_resume_banner.resume', percent: '{percent}')
      }
    end
  end
end
