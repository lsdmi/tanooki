# frozen_string_literal: true

module Contests
  # Live requirements checklist for «Моя участь» and the fiction edit banner.
  class RequirementsChecklistComponent < ViewComponent::Base
    def initialize(entry:, compact: false)
      super()
      @entry = entry
      @contest = entry.contest
      @items = RequirementsProgress.new(entry).call
      @compact = compact
    end

    def render?
      entry.fiction.present? && items.any?
    end

    private

    attr_reader :entry, :contest, :items, :compact

    def row_classes(item)
      [
        'grid grid-cols-1 items-center gap-x-4 gap-y-3 border-b border-line last:border-b-0 last:pb-0',
        'transition-opacity duration-[160ms] motion-reduce:transition-none',
        row_grid,
        ('opacity-[0.72]' if item.met?)
      ].compact.join(' ')
    end

    def row_grid
      return 'py-2 sm:grid-cols-[minmax(0,1fr)_minmax(0,7rem)]' if compact

      'py-3 sm:grid-cols-[minmax(0,1fr)_minmax(0,10rem)]'
    end

    def numeric?(item)
      item.key.in?(%i[chapters words])
    end

    def value_text(item)
      return count_text(item) if numeric?(item)
      return t('contests.progress.rating_value', current: item.current, max: item.required) if item.key == :rating

      item.met? ? t('contests.progress.yes') : t('contests.progress.no')
    end

    def count_text(item)
      t('contests.progress.of', current: delimited(item.current), required: delimited(item.required))
    end

    def delimited(number)
      number_with_delimiter(number, delimiter: ' ')
    end
  end
end
