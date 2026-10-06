# frozen_string_literal: true

# One way a species evolves: into +to+ at +min_level+, only for Pokémon with one of +characters+ when it is set (a
# branch, like Eevee's). Species and evolutions are edited in migrations.
class PokemonEvolution < ApplicationRecord
  belongs_to :from, class_name: 'Pokemon', inverse_of: :evolutions
  belongs_to :to, class_name: 'Pokemon'

  validates :min_level, numericality: { only_integer: true, greater_than: 0 }

  # The evolution a Pokémon with +character+ follows from +species_id+, with its target's sprite loaded.
  def self.next_for(species_id, character)
    where(from_id: species_id).includes(to: { sprite_attachment: :blob }).find { |evolution| evolution.for?(character) }
  end

  def for?(character)
    characters.blank? || characters.include?(character.to_s)
  end
end
