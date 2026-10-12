# frozen_string_literal: true

module Library
  # ⋮ on a /library row (Figma «Shelf menu» 10171:15383): «Перемістити до» the other shelves, the current one checked,
  # then «Прибрати з читальні». A dropdown from md, a bottom sheet below. Moves need no confirm; removing does.
  class ShelfMenuComponent < ViewComponent::Base
    include ReadingStateHelper
    include Ui::StrokeIconHelper

    ICONS = { active: :book_open, finished: :circle_check, postponed: :clock, dropped: :circle_pause }.freeze

    def initialize(reading:, section:)
      super()
      @reading = reading
      @section = section
    end

    private

    attr_reader :reading, :section

    def current_status
      reading.status.to_sym
    end

    def form_options
      { url: update_reading_progress_path(reading), method: :patch, class: 'contents' }
    end

    def remove_confirm
      t('library.shelf_menu.remove_confirm', title: reading.fiction.title)
    end
  end
end
