# frozen_string_literal: true

module Pokemons
  # A block of the Pokémon screen in the fiction page's card shell (Fictions::AboutCardStyles): title, an optional
  # action on its right (a small icon button), then the content. +id+ lands on the section, so Turbo Streams can
  # replace the whole panel; +html+ adds attributes, its +class+ appended to the shell.
  #
  # +fold+ (a key unique on the page) folds the panel to its summary behind a chevron in the header, wired to the
  # panel-fold Stimulus controller: content marked with +open_target+ shows only unfolded, +closed_target+ only folded.
  # The section is the group/fold (+data-open+ while unfolded) and carries a view-transition-name, so it slides when
  # the layout around it changes.
  class PanelComponent < ViewComponent::Base
    SHELL = 'group/fold flex min-w-0 flex-col gap-4 rounded-xl bg-main p-4 ring-1 ring-inset ring-line md:p-5'
    TITLE = 'text-base/6 font-semibold text-fg md:text-lg/7'

    renders_one :action

    def self.open_target
      { panel_fold_target: 'open' }
    end

    def self.closed_target
      { panel_fold_target: 'closed' }
    end

    def initialize(title:, id: nil, subtitle: nil, fold: nil, html: {})
      super()
      @title = title
      @id = id
      @subtitle = subtitle
      @fold = fold
      @html = html
    end

    private

    attr_reader :title, :id, :subtitle, :fold, :html

    def heading_id
      @heading_id ||= "pokemon-panel-#{SecureRandom.hex(4)}"
    end

    def section_attributes
      attributes = html.except(:class).merge(id:, class: [SHELL, html[:class]].compact.join(' '),
                                             aria: { labelledby: heading_id })
      return attributes unless fold

      attributes.merge(data: { controller: 'panel-fold', panel_fold_key_value: fold },
                       style: "view-transition-name: pokemon-#{fold}; view-transition-class: pokemon-panel")
    end
  end
end
