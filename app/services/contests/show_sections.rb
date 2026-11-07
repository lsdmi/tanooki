# frozen_string_literal: true

module Contests
  # Orders ShowMatrix sections for a phase and flags which are visible for the presenter's role.
  class ShowSections
    def initialize(presenter)
      @presenter = presenter
    end

    def call
      ordered_definitions.map { |definition| build(definition) }
    end

    private

    attr_reader :presenter

    def ordered_definitions
      by_id = ShowMatrix::SECTIONS.index_by { |definition| definition[:id] }
      pinned = ShowMatrix::LEAD_SECTIONS.fetch(presenter.phase, []).filter_map { |id| by_id[id] }
      pinned + (ShowMatrix::SECTIONS - pinned)
    end

    def build(definition)
      {
        id: definition[:id],
        anchor: definition[:anchor],
        nav: definition[:nav],
        nav_links: definition[:nav_links],
        partial_or_component: definition[:component] || definition[:partial],
        visible: visible?(definition)
      }
    end

    def visible?(definition)
      return false if presenter.phase == :draft

      allowed?(definition[:phases], presenter.phase) &&
        allowed?(definition[:roles], presenter.role) &&
        condition_met?(definition[:if])
    end

    def allowed?(list, value)
      list.nil? || list.include?(value)
    end

    def condition_met?(predicate)
      predicate.nil? || presenter.public_send(predicate)
    end
  end
end
