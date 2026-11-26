# frozen_string_literal: true

module Fictions
  # Option and selection names for the «Теґи» multi-select in the fiction form.
  module TagFieldHelper
    # Names the form should show as selected: the submitted choice after a failed save, else the saved tags.
    def fiction_tag_selected_names(fiction)
      return fiction.tag_names unless fiction.tag_names.nil?

      fiction.fiction_tags.order(:name).pluck(:name)
    end

    # Whatever is already selected (hidden tags the work carries, new names just typed) first, each group
    # alphabetical; then the remaining active tags, alphabetical. Selected spellings go first so a
    # differently-cased duplicate never hides the selected one. The option order is the chip order.
    def fiction_tag_option_names(selected_names)
      selected = selected_names.uniq(&:downcase).sort_by(&:downcase)
      others = FictionTag.active.pluck(:name).sort_by(&:downcase)
      (selected + others).uniq(&:downcase)
    end
  end
end
