# frozen_string_literal: true

module Library
  # Library card state for one reading: «Прочитано: N / total», the «Читати далі» target and «Все прочитано».
  # Driven by `Reading::ReadKeys`, never by where the resume chapter sits in the list.
  # A fiction marked finished counts as fully read, matching the reader drawer.
  class ContinueReadingPresenter
    def initialize(reading, viewer:)
      @reading = reading
      @viewer = viewer
    end

    def total
      listable.size
    end

    def read_count
      return total if @reading.finished?

      listable.count { |chapter| read?(chapter) }
    end

    def all_read?
      return true if @reading.finished?

      latest = listable.first
      latest.present? && read?(latest)
    end

    # Resume chapter, unless they already finished it: then send them onward. Nil when nothing is listable.
    def continue_chapter
      return @continue_chapter if defined?(@continue_chapter)

      @continue_chapter = resolve_continue_chapter
    end

    private

    def resolve_continue_chapter
      resume = @reading.chapter
      return listable.last unless resume
      return resume unless read?(resume)

      ChapterNavigation.following_chapter(@reading.fiction, resume, viewer: @viewer) || resume
    end

    def read?(chapter)
      read_keys.include?(ReadingChapterRead.chapter_key(chapter))
    end

    def listable
      @listable ||= ChapterNavigation.unique_chapters(
        ChapterCatalog.ordered_chapters_desc(@reading.fiction, viewer: @viewer)
      )
    end

    def read_keys
      @read_keys ||= Reading::ReadKeys.call(user: @viewer, fiction: @reading.fiction, progress: @reading)
    end
  end
end
