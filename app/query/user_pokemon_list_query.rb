# frozen_string_literal: true

# Loads a user's party ordered by Pokédex id with sprites preloaded.
class UserPokemonListQuery
  def initialize(user)
    @user = user
  end

  def call
    UserPokemon
      .includes(pokemon: :sprite_attachment)
      .where(user_id: @user.id)
      .order('pokemons.dex_id')
  end
end
