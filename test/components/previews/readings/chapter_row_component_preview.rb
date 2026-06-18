# frozen_string_literal: true

module Readings
  class ChapterRowComponentPreview < ViewComponent::Preview
    # @label Table and card variants
    def variants
      render_with_template(
        template: 'readings/chapter_row_component_preview/variants',
        locals: { chapter: sample_chapter }
      )
    end

    private

    def sample_chapter
      Chapter.order(created_at: :desc).first ||
        raise('Add at least one chapter to the development database to preview Readings::ChapterRowComponent.')
    end
  end
end
