# frozen_string_literal: true

module Pokemons
  # The battle log rendered from a PokemonBattle's stored events: one card per round (the Pokémon that fainted dimmed
  # and marked), then the result. Species come from the stored teams, so a Pokémon that evolved later still shows as
  # it fought. A legacy battle has no events: a note and the result only.
  class BattleReplayComponent < ViewComponent::Base
    Round = Data.define(:number, :attacker, :defender, :victory)
    SPRITE_RING = 'flex size-10 shrink-0 items-center justify-center rounded-full bg-main ring-1 ring-inset ring-line'

    def initialize(battle:)
      super()
      @battle = battle
    end

    private

    attr_reader :battle

    def rounds
      @rounds ||= battle.events_of(:round_started).zip(battle.events_of(:fainted)).map.with_index(1) do |events, number|
        start, fainted = events.map { |event| event['data'] }
        Round.new(number:, attacker: species_of(start['attacker']), defender: species_of(start['defender']),
                  victory: fainted['side'] == 'defender')
      end
    end

    def winner_name
      battle.winner.name
    end

    def loser_name
      (battle.attacker_won? ? battle.defender : battle.attacker).name
    end

    def fighter(pokemon, fainted:, align: :start)
      tag.div(class: ['flex min-w-0 items-center gap-2', ('flex-row-reverse text-right' if align == :end)]) do
        safe_join([tag.div(sprite(pokemon), class: [SPRITE_RING, ('opacity-50 grayscale' if fainted)]),
                   tag.div(class: 'flex min-w-0 flex-col') do
                     safe_join([tag.span(pokemon&.name, class: ['truncate text-sm/5 font-medium',
                                                                fainted ? 'text-fg-muted' : 'text-fg']),
                                (tag.span('вибуває', class: 'text-xs/4 text-status-danger-solid') if fainted)])
                   end])
      end
    end

    # A species deleted since the battle shows an empty ring.
    def sprite(pokemon)
      return unless pokemon&.sprite&.attached?

      image_tag(url_for(pokemon.sprite), alt: pokemon.name, class: 'size-9 object-contain')
    end

    def species_of(combatant_id)
      species[pokemon_ids[combatant_id]]
    end

    def pokemon_ids
      @pokemon_ids ||= (battle.attacker_team + battle.defender_team).to_h { |entry| [entry['id'], entry['pokemon_id']] }
    end

    def species
      @species ||= Pokemon.where(id: pokemon_ids.values.uniq).includes(sprite_attachment: :blob).index_by(&:id)
    end
  end
end
