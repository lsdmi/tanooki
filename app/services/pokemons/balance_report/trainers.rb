# frozen_string_literal: true

module Pokemons
  class BalanceReport
    # Real collections for team battles: each trainer's Pokémon as [species, experience, character] entries, for
    # those who battled in the last RECENT. With fewer than MIN_TRAINERS of them (a stale dev copy), everyone with a
    # full team stands in.
    module Trainers
      RECENT = 90.days
      MIN_TRAINERS = 100
      FULL_TEAM = 6

      def self.load(species, min_trainers: MIN_TRAINERS)
        by_id = species.index_by(&:id)
        rows = scope(min_trainers).order(:id).pluck(:user_id, :pokemon_id, :battle_experience, :character)
        rows.group_by(&:first).values.map do |collection|
          collection.map { |_, pokemon_id, experience, character| [by_id.fetch(pokemon_id), experience, character] }
        end
      end

      def self.scope(min_trainers)
        recent = PokemonBattle.where(created_at: RECENT.ago..).distinct.pluck(:attacker_id, :defender_id).flatten.uniq
        return UserPokemon.where(user_id: recent) if recent.size >= min_trainers

        UserPokemon.where(user_id: UserPokemon.group(:user_id).having('COUNT(*) >= ?', FULL_TEAM).select(:user_id))
      end
    end
  end
end
