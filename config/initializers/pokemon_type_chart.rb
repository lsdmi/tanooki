# frozen_string_literal: true

# Loads and checks config/type_advantage.yml at boot, so an incomplete chart fails the deploy instead of a battle.
Rails.application.config.to_prepare { Pokemons::Engine::TypeChart.default }
