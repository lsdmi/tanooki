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

    private

    def target
      @target ||= Reading::ContinueTarget.new(progress: @reading, viewer: @viewer, listable:, read_keys:)
    end

    def listable
      @listable ||= ChapterNavigation.unique_chapters(
        ChapterCatalog.ordered_chapters_desc(@reading.fiction, viewer: @viewer)
      )
    end

    def read_keys
      Reading::ReadKeys.call(user: @viewer, fiction: @reading.fiction, progress: @reading)
    end
  end
end
