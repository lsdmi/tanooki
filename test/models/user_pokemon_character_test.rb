# frozen_string_literal: true

require 'test_helper'

class UserPokemonCharacterTest < ActiveSupport::TestCase
  setup do
    @user_pokemon = user_pokemons(:one)
  end

  test 'character is stored as its key and labelled in Ukrainian' do
    @user_pokemon.update!(character: 'hardy')

    assert_equal 'hardy', UserPokemon.where(id: @user_pokemon).pick(:character)
    assert_equal 'Витривалий', @user_pokemon.character_label
  end

  test 'a Ukrainian label written by the previous release reads as its key' do
    UserPokemon.connection.update("UPDATE user_pokemons SET `character` = 'Таланистий' WHERE id = #{@user_pokemon.id}")

    assert_equal 'lucky', @user_pokemon.reload.character
    assert_equal 'Таланистий', @user_pokemon.character_label
  end

  test 'an unknown character is rejected' do
    assert_raises(ArgumentError) { @user_pokemon.character = 'grumpy' }
  end
end
