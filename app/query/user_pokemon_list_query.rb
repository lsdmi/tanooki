# frozen_string_literal: true

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
