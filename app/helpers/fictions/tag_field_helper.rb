# frozen_string_literal: true

module Fictions
  # Option and selection names for the «Теґи» multi-select in the fiction form.
  module TagFieldHelper
    # Names the form should show as selected: the submitted choice after a failed save, else the saved tags.
    def fiction_tag_selected_names(fiction)
      return fiction.tag_names unless fiction.tag_names.nil?

      fiction.fiction_tags.order(:name).pluck(:name)
    end

    # Whatever is already selected (hidden tags the work carries, new names just typed) plus the active tags.
    # Selected names go first so a differently-cased duplicate never hides the selected spelling.
    def fiction_tag_option_names(selected_names)
      (selected_names + FictionTag.active.order(:name).pluck(:name)).uniq(&:downcase)
    end
  end
end
