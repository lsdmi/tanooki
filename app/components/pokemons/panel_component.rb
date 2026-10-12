# frozen_string_literal: true

module Pokemons
  # A block of the Studio Pokémon tab. +tone+ :journal (default) is a divider strip without a card shell; :arena is the
  # battle stage. +fold+ wires panel-fold; +open_target+ / +closed_target+ mark what shows unfolded / folded. WIDE and
  # NARROW switch the folded summary when the group/row is half-width or full-width.
  class PanelComponent < ViewComponent::Base
    TONES = {
      journal: 'group/fold flex min-w-0 flex-col gap-4 border-b border-line py-6 last:border-b-0 last:pb-0',
      arena: 'group/fold relative flex min-w-0 flex-col gap-5 overflow-hidden rounded-2xl bg-surface px-5 py-6 ' \
             'ring-1 ring-inset ring-line md:px-8 md:py-8'
    }.freeze
    TITLE = 'text-lg/7 font-semibold tracking-tight text-fg'
    WIDE = 'hidden sm:flex lg:hidden lg:group-has-[[data-open]]/row:flex'
    NARROW = 'flex sm:hidden lg:flex lg:group-has-[[data-open]]/row:hidden'

    renders_one :action

    def self.open_target
      { panel_fold_target: 'open' }
    end

    def self.closed_target
      { panel_fold_target: 'closed' }
    end

    # +tone+ and +fold+ arrive in +options+ so the keyword list stays short for RuboCop.
    def initialize(title:, id: nil, subtitle: nil, html: {}, **options)
      super()
      @title = title
      @id = id
      @subtitle = subtitle
      @fold = options[:fold]
      @tone = options.fetch(:tone, :journal).to_sym
      @html = html
      raise ArgumentError, "unknown tone: #{@tone}" unless TONES.key?(@tone)
    end

    private

    attr_reader :title, :id, :subtitle, :fold, :tone, :html

    def heading_id
      @heading_id ||= "pokemon-panel-#{SecureRandom.hex(4)}"
    end

    def shell
      TONES.fetch(tone)
    end

    def section_attributes
      attributes = html.except(:class).merge(id:, class: [shell, html[:class]].compact.join(' '),
                                             aria: { labelledby: heading_id })
      return attributes unless fold

      attributes.merge(data: { controller: 'panel-fold', panel_fold_key_value: fold },
                       style: "view-transition-name: pokemon-#{fold}; view-transition-class: pokemon-panel")
    end
  end
end
