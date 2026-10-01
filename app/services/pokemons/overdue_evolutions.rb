# frozen_string_literal: true

module Pokemons
  # One-off repair: Pokémon that reached their evolution level but never evolved, because the old catch path compared
  # the level with the caught base form, using ==. Reports only unless apply: true.
  class OverdueEvolutions
    Row = Data.define(:user_pokemon_id, :user_id, :level, :from, :to)

    def self.call(apply: false)
      new.call(apply:)
    end

    def call(apply:)
      candidates.filter_map do |user_pokemon|
        from = user_pokemon.pokemon
        to = user_pokemon.ready_species
        next if to == from

        user_pokemon.evolve_if_ready! if apply
        Row.new(user_pokemon.id, user_pokemon.user_id, user_pokemon.current_level, from.name, to.name)
      end
    end

    private

    def candidates
      UserPokemon.joins(:pokemon).includes(:pokemon).order(:id)
                 .where('pokemons.descendant_id <> pokemons.id AND pokemons.descendant_level > 0')
                 .where('user_pokemons.current_level >= pokemons.descendant_level')
    end
  end
end
