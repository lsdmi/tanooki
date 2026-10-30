# frozen_string_literal: true

module Ui
  # Collapse overflow pills below lg / sm breakpoints for dense catalog rows.
  module TagListCompact
    private

    # Below lg only the first compact_max pills stay, with a +N pill standing in for the rest.
    # Optional compact_max_sm tightens that further below sm (e.g. 2 on phone, 3 until lg).
    def compact_collapsed?
      compact_max.present? && visible_labels.size > compact_max
    end

    def compact_sm_collapsed?
      compact_max_sm.present? && visible_labels.size > compact_max_sm
    end

    def compact_overflow_count
      visible_labels.size - compact_max
    end

    def compact_sm_overflow_count
      visible_labels.size - compact_max_sm
    end

    # max-*:hidden rather than a bare hidden: the pill's base inline-flex would otherwise
    # win or lose on stylesheet order instead of breakpoint.
    def tag_html_for(label)
      hide_classes = compact_hide_classes_for(label)
      return tag_html if hide_classes.empty?

      tag_html.merge(class: [tag_html[:class], *hide_classes].compact.join(' '))
    end

    def compact_hide_classes_for(label)
      index = visible_labels.index(label).to_i
      classes = []
      classes << 'max-lg:hidden' if compact_collapsed? && index >= compact_max
      classes << 'max-sm:hidden' if compact_sm_collapsed? && index >= compact_max_sm && index < compact_max.to_i
      classes
    end
  end
end
