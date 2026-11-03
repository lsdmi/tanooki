# frozen_string_literal: true

require_relative 'preview_support'

module Contests
  class ArchiveCardComponentPreview < ViewComponent::Preview
    layout 'component_preview'

    def default
      contest = PreviewSupport.sample_contest(phase: :results)
      render(ArchiveCardComponent.new(contest:, entry_count: 12, top_covers: []))
    end
  end
end
