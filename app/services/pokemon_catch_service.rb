# frozen_string_literal: true

class PokemonCatchService
  attr_reader :pokemon_id, :user_id, :session

  def initialize(pokemon_id:, user_id:, session:)
    @pokemon_id = pokemon_id
    @user_id = user_id
    @session = session
  end

  def trap
    user_pokemon = find_or_create_user_pokemon
    update_user_pokemon(user_pokemon)
  end

  private

  def sample_character
    UserPokemon.characters.to_a.sample.second
  end

  def find_or_create_user_pokemon
    pokemon_data.descendants.each do |pokemon|
      user_pokemon = UserPokemon.find_by(user_id:, pokemon_id: pokemon.id)
      return user_pokemon if user_pokemon
    end

    UserPokemon.create(user_id:, pokemon_id:, character: sample_character)
  end

  def update_user_pokemon(user_pokemon)
    user_pokemon.update(current_level: user_pokemon.current_level + 1)

    return unless user_pokemon.current_level == pokemon_data.descendant_level

    user_pokemon.update(pokemon_id: pokemon_data.descendant_id)
  end

  def pokemon_data
    @pokemon_data ||= Pokemon.find_by(id: pokemon_id)
  end
end
