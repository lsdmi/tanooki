# frozen_string_literal: true

module Fictions
  class ShowcaseSlideOverlayComponentPreview < ViewComponent::Preview
    SampleFiction = Struct.new(:title, :description, :author, :average_rating, :views, keyword_init: true)

    # @label Mobile minimal
    def mobile_minimal
      render_with_template(
        template: 'fictions/showcase_slide_overlay_component_preview/mobile_minimal',
        locals: { slide: sample_slide(layout: :mobile_minimal) }
      )
    end

    # @label Full overlay
    def full
      render_with_template(
        template: 'fictions/showcase_slide_overlay_component_preview/full',
        locals: { slide: sample_slide(layout: :full, editorial_kinds: %i[popular]) }
      )
    end

    # @label Mobile vs full comparison
    def comparison
      render_with_template(
        template: 'fictions/showcase_slide_overlay_component_preview/comparison',
        locals: {
          mobile_slide: sample_slide(layout: :mobile_minimal),
          full_slide: sample_slide(layout: :full, editorial_kinds: %i[popular])
        }
      )
    end

    private

    def sample_fiction
      @sample_fiction ||= SampleFiction.new(
        title: 'Точка зору всезнаючого читача',
        description: 'Життя Кіма Докджі обертається навколо читання одного веб-роману ' \
                     '«Три способи вижити у зруйнованому світі».',
        author: 'singNsong',
        average_rating: 4.9,
        views: 25_700
      )
    end

    def sample_slide(layout:, editorial_kinds: %i[update])
      Fictions::ShowcaseSlideOverlayComponent.new(
        fiction: sample_fiction,
        editorial_kinds: editorial_kinds,
        links: { read: '#', fiction: '#' },
        layout: layout
      )
    end
  end
end
