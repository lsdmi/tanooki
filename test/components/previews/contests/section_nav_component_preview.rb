# frozen_string_literal: true

require_relative 'preview_support'

module Contests
  class SectionNavComponentPreview < ViewComponent::Preview
    layout 'component_preview'

    def default
      render(SectionNavComponent.new(presenter: PreviewSupport.sample_presenter))
    end
  end
end
