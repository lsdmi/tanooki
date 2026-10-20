# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Items
    class UseTest < ActiveSupport::TestCase
      setup do
        Catalog.reload!
        @user = users(:user_one)
        @profile = @user.trainer_profile
        @profile.update!(item_effects: {}, last_training_at: 1.hour.ago, last_battle_at: 1.hour.ago)
        TrainerItem.where(user: @user).delete_all
      end

      test 'protein levels up a party pokemon and spends one' do
        Grant.call(@user, item_key: 'protein')
        pokemon = @user.user_pokemons.first
        level = pokemon.current_level

        notice = Use.call(@user, item_key: 'protein', user_pokemon_id: pokemon.id)

        assert_match(/рівень/i, notice)
        assert_equal level + 1, pokemon.reload.current_level
        assert_equal 0, TrainerItem.find_by!(user: @user, item_key: 'protein').quantity
      end

      test 'training tonic clears the training clock' do
        Grant.call(@user, item_key: 'training_tonic')

        assert Use.call(@user, item_key: 'training_tonic')
        assert_nil @profile.reload.last_training_at
      end

      test 'lure stores a pokemon type key' do
        Grant.call(@user, item_key: 'lure')

        assert Use.call(@user, item_key: 'lure', habitat: 'dragon')
        assert_equal 'dragon', @profile.reload.item_effect('lure')
      end

      test 'missing stock returns nil' do
        assert_nil Use.call(@user, item_key: 'protein', user_pokemon_id: @user.user_pokemons.first.id)
      end
    end
  end
end
