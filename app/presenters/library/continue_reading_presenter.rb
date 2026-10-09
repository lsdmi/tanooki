# frozen_string_literal: true

module Library
  # Library card state for one reading: «Прочитано: N / total», the «Читати далі» target and «Все прочитано».
  # Driven by `Reading::ReadKeys`, never by where the resume chapter sits in the list.
  # A fiction marked finished counts as fully read, matching the reader drawer.
  # Where continue goes is `Reading::ContinueTarget`, shared with the fiction page «Продовжити».
  class ContinueReadingPresenter
    delegate :all_read?, :resume?, to: :target

    def initialize(reading, viewer:)
      @reading = reading
      @viewer = viewer
    end

    def total
      listable.size
    end

    def read_count
      return total if @reading.finished?

      listable.count { |chapter| target.read?(chapter) }
    end

    def continue_chapter
      target.chapter
    end

    # The reader stopped on a chapter hidden by a licence takedown, so there is no chapter to continue in.
    def license_hidden?
      @reading.chapter&.license_hidden? || false
    end

    # Putting a fiction on a shelf creates a progress on the first chapter; it counts as started only once a
    # chapter was opened (resume_at) or read.
    def started?
      return @started if defined?(@started)

      @started = @reading.resume_at.present? || read_count.positive?
    end

    private

    def target
      @target ||= Reading::ContinueTarget.new(progress: @reading, viewer: @viewer, listable:, read_keys:)
    end

    def listable
      @listable ||= ChapterNavigation.unique_chapters(ChapterCatalog.listed_chapters(@reading.fiction, viewer: @viewer))
    end

    def read_keys
      Reading::ReadKeys.call(user: @viewer, fiction: @reading.fiction, progress: @reading)
    end
  end
end
