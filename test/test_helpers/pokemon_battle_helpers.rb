# frozen_string_literal: true

# A stored battle without running the engine, for tests that only need "these two fought" (cooldowns, history).
module PokemonBattleHelpers
  def create_pokemon_battle(attacker:, defender:, winner: attacker, **attributes)
    PokemonBattle.create!(attacker:, defender:, winner:, seed: 1, engine_version: Pokemons::Engine::VERSION,
                          attacker_team: [], defender_team: [], events: [], rating_delta_attacker: 0,
                          rating_delta_defender: 0, **attributes)
  end
end
