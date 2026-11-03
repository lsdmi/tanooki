# frozen_string_literal: true

module Contests
  # Sticky section anchors with the primary action pinned on desktop.
  class SectionNavComponent < ViewComponent::Base
    def initialize(presenter:)
      super()
      @presenter = presenter
    end

    private

    attr_reader :presenter

    def items
      presenter.nav_items
    end

    def primary
      presenter.primary_action
    end

    def action_label(action)
      t(action[:label_key], **action.fetch(:label_args, {}))
    end
  end
end
