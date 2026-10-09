# frozen_string_literal: true

module Pokemons
  # A block of the Pokémon screen in the fiction page's card shell (Fictions::AboutCardStyles): title, an optional
  # action on its right (a small icon button), then the content. +id+ lands on the section, so Turbo Streams can
  # replace the whole panel; +html+ adds attributes, its +class+ appended to the shell.
  class PanelComponent < ViewComponent::Base
    SHELL = 'flex min-w-0 flex-col gap-4 rounded-xl bg-main p-4 ring-1 ring-inset ring-line md:p-5'
    TITLE = 'text-base/6 font-semibold text-fg md:text-lg/7'

    renders_one :action

    def initialize(title:, id: nil, subtitle: nil, html: {})
      super()
      @title = title
      @id = id
      @subtitle = subtitle
      @html = html
    end

    private

    attr_reader :title, :id, :subtitle, :html

    def heading_id
      @heading_id ||= "pokemon-panel-#{SecureRandom.hex(4)}"
    end

    def section_attributes
      html.except(:class).merge(id:, class: [SHELL, html[:class]].compact.join(' '), aria: { labelledby: heading_id })
    end
  end
end
