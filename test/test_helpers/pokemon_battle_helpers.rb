# frozen_string_literal: true

# A stored battle without running the engine, for tests that only need "these two fought" (cooldowns, history).
# Stamps both trainers' last_battle_at like Pokemons::BattleStart does.
module PokemonBattleHelpers
  def create_pokemon_battle(attacker:, defender:, winner: attacker, **attributes)
    battle = PokemonBattle.create!(attacker:, defender:, winner:, seed: 1, engine_version: Pokemons::Engine::VERSION,
                                   attacker_team: [], defender_team: [], events: [], rating_delta_attacker: 0,
                                   rating_delta_defender: 0, **attributes)
    [attacker, defender].each do |user|
      profile = user.trainer_profile
      profile.update!(last_battle_at: battle.created_at) unless profile.last_battle_at&.after?(battle.created_at)
    end
    battle
  end
end
