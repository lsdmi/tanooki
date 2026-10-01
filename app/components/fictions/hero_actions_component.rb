# frozen_string_literal: true

module Fictions
  # Hero band buttons and progress line (Figma «Hero band» 10088:10422 → Actions). Re-rendered on its own by
  # ReadingProgressesController#update_status, so a shelf change also refreshes «Читати знову» and the progress line.
  # Guests get the cached markup; `guest-continue` swaps in «Продовжити» from the reading record on their device.
  class HeroActionsComponent < ViewComponent::Base
    include Layout::TurboDriveHelper
    include Library::ReadingStateHelper
    include Ui::StrokeIconHelper

    DOM_ID = 'fiction-hero-actions'

    def initialize(fiction:, presenter:, user:)
      super()
      @fiction = fiction
      @presenter = presenter
      @user = user
    end

    private

    attr_reader :fiction, :presenter, :user

    delegate :first_chapter, :reading_progress, to: :presenter, private: true

    def guest?
      user.nil?
    end

    def continue_reading
      return unless reading_progress

      @continue_reading ||= Library::ContinueReadingPresenter.new(reading_progress, viewer: user)
    end

    # Putting a fiction on a shelf creates a progress on the first chapter; it counts as started only once a
    # chapter was opened (resume_at) or read.
    def started?
      return @started if defined?(@started)

      @started = continue_reading.present? &&
                 (reading_progress.resume_at.present? || continue_reading.read_count.positive?)
    end

    def cta_kind
      if continue_reading&.all_read?
        :reread if first_chapter
      elsif started? && continue_reading.continue_chapter
        :continue
      elsif first_chapter
        :read
      end
    end

    def cta?
      cta_kind.present?
    end

    def cta_href
      return chapter_path(first_chapter) unless cta_kind == :continue

      chapter_path(continue_reading.continue_chapter, resume: (1 if continue_reading.resume?))
    end

    def cta_label
      case cta_kind
      when :continue then t('fictions.hero.cta.continue', number: chapter_number(continue_reading.continue_chapter))
      when :reread then t('fictions.hero.cta.reread')
      else read_label
      end
    end

    def read_label
      t('fictions.hero.cta.read', number: chapter_number(first_chapter))
    end

    def cta_html
      data = guest? ? { guest_continue_target: 'link' } : {}
      turbo_drive_visit_data(preload: true).deep_merge(data:, class: 'w-full md:w-auto')
    end

    def guest_continue_attributes
      return {} unless guest? && cta?

      { data: guest_continue_data(fiction, first_chapter, read_label:) }
    end

    def chapter_number(chapter)
      Chapters::Formatting.format_decimal(chapter.number)
    end

    def shelf_status
      reading_progress&.status&.to_sym
    end

    def shelf_label
      return t('fictions.hero.library.add') unless shelf_status

      t('fictions.hero.library.current', status: status_label_for(shelf_status))
    end

    def shelf_sheet_title
      shelf_status ? t('fictions.hero.library.move_to') : t('fictions.hero.library.add')
    end

    def status_path
      update_status_fiction_reading_progress_path(fiction)
    end

    def login_path
      new_user_session_path(return_to: fiction_path(fiction))
    end

    # «востаннє» is the last chapter visit; a shelf change also touches updated_at, so it is not a fallback.
    def progress_line
      return unless started? && continue_reading.total.positive?

      counts = { read: continue_reading.read_count, total: continue_reading.total }
      visited_at = reading_progress.resume_at
      return t('fictions.hero.progress', **counts) unless visited_at

      t('fictions.hero.progress_with_time', **counts, time: time_ago_in_words(visited_at, locale: :uk))
    end
  end
end
