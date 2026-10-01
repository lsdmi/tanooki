# frozen_string_literal: true

# Turns the fixtures into a three-stage line: one -> two -> three.
module PokemonEvolutionLineHelpers
  private

  # Fixtures have no sprite, which Pokemon validates, so save without validations.
  def make_three_stage_line(stage_two_at:, stage_three_at:)
    evolve_into(pokemons(:one), pokemons(:two), stage_two_at)
    evolve_into(pokemons(:two), pokemons(:three), stage_three_at)
  end

  def evolve_into(from, to, level)
    from.assign_attributes(descendant: to, descendant_level: level)
    from.save!(validate: false)
  end
end
