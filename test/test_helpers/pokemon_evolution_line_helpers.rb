# frozen_string_literal: true

# Turns the fixtures into a three-stage line: one -> two -> three.
module PokemonEvolutionLineHelpers
  private

  def make_three_stage_line(stage_two_at:, stage_three_at:)
    evolve_into(pokemons(:one), pokemons(:two), stage_two_at)
    evolve_into(pokemons(:two), pokemons(:three), stage_three_at)
  end

  def evolve_into(from, to, level, characters: nil)
    evolution = PokemonEvolution.find_or_initialize_by(from:, to:)
    evolution.update!(min_level: level, characters:)
  end

  # A wild first form of its own line. It has no sprite, which Pokemon validates, so save without validations; the id
  # is set up front because line_root_id (a foreign key) points at the row itself.
  def create_line_root(name, dex_id:)
    id = Pokemon.maximum(:id).to_i + 1
    species = Pokemon.new(id:, line_root_id: id, name:, slug: name.parameterize, rarity: 1, wild: true, dex_id:,
                          **Pokemons::BaseStats.for(dex_id).transform_keys(hp: :base_hp, attack: :base_attack))
    species.save!(validate: false)
    species
  end
end
