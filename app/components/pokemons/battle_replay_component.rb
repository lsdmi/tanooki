# frozen_string_literal: true

module Pokemons
  # The battle log rendered from a PokemonBattle's stored events: the arena header, one card per round in a two-column
  # grid, and the result (in the grid's last cell when the round count is odd). Species come from the stored teams, so
  # a Pokémon that evolved later still shows as it fought. A legacy battle has no events: header and result only.
  class BattleReplayComponent < ViewComponent::Base
    Round = Data.define(:number, :attacker, :defender, :victory)
    NAME_LENGTH = 7
    AVATAR_RING = 'flex items-center justify-center h-14 w-14 border-2 border-line shadow dark:shadow-lg ' \
                  'rounded-full mb-2 transition-transform duration-300 hover:scale-105'

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

    def result_in_grid?
      rounds.size.odd?
    end

    def winner_name
      battle.winner.name
    end

    def loser_name
      (battle.attacker_won? ? battle.defender : battle.attacker).name
    end

    def avatar(pokemon)
      tag.div(class: 'flex flex-col items-center justify-center text-center') do
        safe_join([tag.div(sprite(pokemon), class: AVATAR_RING),
                   tag.span(short_name(pokemon), class: 'font-semibold text-xs sm:text-sm text-fg mt-1 tracking-wide')])
      end
    end

    def sprite(pokemon)
      return unless pokemon&.sprite&.attached?

      image_tag(url_for(pokemon.sprite), alt: pokemon.name, class: 'w-10 h-10 object-contain rounded-full')
    end

    # A species deleted since the battle shows an empty ring.
    def short_name(pokemon)
      name = pokemon&.name.to_s
      name.length > NAME_LENGTH ? "#{name[0, NAME_LENGTH]}..." : name
    end

    def species_of(combatant_id)
      species[pokemon_ids[combatant_id]]
    end

    def pokemon_ids
      @pokemon_ids ||= (battle.attacker_team + battle.defender_team).to_h { |entry| [entry['id'], entry['pokemon_id']] }
    end

    def species
      @species ||= Pokemon.where(id: pokemon_ids.values.uniq).with_attached_sprite.index_by(&:id)
    end
  end
end
