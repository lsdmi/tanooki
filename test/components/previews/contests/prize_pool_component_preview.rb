# frozen_string_literal: true

require_relative 'preview_support'

module Contests
  class PrizePoolComponentPreview < ViewComponent::Preview
    layout 'component_preview'

    def default
      render(PrizePoolComponent.new(presenter: PreviewSupport.sample_presenter))
    end
  end
end
