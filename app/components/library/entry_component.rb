# frozen_string_literal: true

module Library
  # One /library row (Figma «Library entry» 10167:15051): cover, title, the reading state as a meta line and mini
  # bar, the next step, and the shelf menu. The whole row opens the fiction page; the button goes straight to reading.
  # States: in progress, not started, caught up, and licensed (stopped on a chapter the licence hides).
  class EntryComponent < ViewComponent::Base
    include EntryComponentStyles
    include Layout::TurboDriveHelper
    include Ui::StrokeIconHelper

    def initialize(reading:, section:, viewer:, preload: false)
      super()
      @reading = reading
      @section = section
      @viewer = viewer
      @preload = preload
    end

    private

    attr_reader :reading, :section, :viewer, :preload

    delegate :fiction, to: :reading

    def progress
      @progress ||= ContinueReadingPresenter.new(reading, viewer:)
    end

    def state
      @state ||= if progress.license_hidden? then :licensed
                 elsif progress.all_read? then :caught_up
                 elsif progress.started? then :in_progress
                 else :not_started
                 end
    end

    def meta
      @meta ||= case state
                when :licensed then t('library.entry.licensed', number: chapter_number(reading.chapter))
                when :caught_up then t('library.entry.caught_up', **counts)
                when :not_started then t('library.entry.not_started', count: progress.total)
                else in_progress_meta
                end
    end

    def in_progress_meta
      chapter = progress.continue_chapter
      return t('library.entry.progress', **counts) unless chapter

      t('library.entry.in_progress', **counts, number: chapter_number(chapter))
    end

    def counts
      { read: progress.read_count, total: progress.total }
    end

    def bar
      return licensed_bar if state == :licensed

      Ui::MiniProgressBarComponent.new(**counts, check: false, html: { class: BAR, aria: { label: meta } })
    end

    def licensed_bar
      Ui::MiniProgressBarComponent.new(read: progress.license_read_count, total: fiction.license_preview.released_count,
                                       tone: :licensed, html: { class: BAR, aria: { label: meta } })
    end

    # A licensed work reads on in the official edition once the preview is done or out of reach.
    def action
      return :official if official_edition?
      return :chapters unless progress.continue_chapter

      { in_progress: :continue, not_started: :start }.fetch(state, :chapters)
    end

    def official_edition?
      fiction.licensed? && fiction.license_url.present? && %i[licensed caught_up].include?(state)
    end

    def continue_href
      chapter_path(progress.continue_chapter, resume: (1 if progress.resume?))
    end

    def continue_html
      turbo_drive_visit_data(preload:)
    end

    def cover_data
      { controller: 'lazy-image', lazy_image_target: 'image',
        lazy_image_url_value: helpers.cover_card_url(fiction.cover) }
    end

    def chapter_number(chapter)
      Chapters::Formatting.format_decimal(chapter.number)
    end
  end
end
