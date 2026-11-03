# frozen_string_literal: true

require_relative 'preview_support'

module Contests
  class TimelineComponentPreview < ViewComponent::Preview
    layout 'component_preview'

    def default
      render(TimelineComponent.new(presenter: PreviewSupport.sample_presenter))
    end
  end
end
