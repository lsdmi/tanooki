# frozen_string_literal: true

require_relative 'preview_support'

module Contests
  class SummaryComponentPreview < ViewComponent::Preview
    layout 'component_preview'

    def default
      render(SummaryComponent.new(presenter: PreviewSupport.sample_presenter))
    end
  end
end
