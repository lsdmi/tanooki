# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class TeamRosterTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @one = user_pokemons(:one)
      @extra = UserPokemon.create!(user: @user, pokemon: pokemons(:four), character: :brave, battle_experience: 40)
    end

    test 'auto-fills up to TEAM_SIZE by power when the roster is blank' do
      @user.trainer_profile.update!(attack_team_ids: nil)
      weak = user_pokemons(:one)
      weak.update!(battle_experience: 0)
      @extra.update!(battle_experience: 100)

      ids = TeamRoster.new(@user, :attack).ids

      assert_operator ids.size, :<=, Balance::TEAM_SIZE
      assert_equal @extra.id, ids.first
    end

    test 'uses the configured attack order when every id is still owned' do
      @user.trainer_profile.update!(attack_team_ids: [@extra.id, @one.id])

      assert_equal [@extra.id, @one.id], TeamRoster.new(@user, :attack).ids
    end

    test 'falls back when a configured id left the party' do
      profile = @user.trainer_profile
      profile.attack_team_ids = [@extra.id, 0]
      profile.save!(validate: false)

      assert_not_includes TeamRoster.new(@user, :attack).ids, 0
      assert_operator TeamRoster.new(@user, :attack).ids.size, :>=, 1
    end

    test 'update! stores a defense roster and rejects foreign ids' do
      TeamRoster.update!(@user, role: :defense, user_pokemon_ids: [@one.id, @extra.id])

      assert_equal [@one.id, @extra.id], @user.trainer_profile.reload.defense_team_ids

      assert_raises(ArgumentError) do
        TeamRoster.update!(@user, role: :attack, user_pokemon_ids: [user_pokemons(:two).id])
      end
    end

    test 'update! clears the column when the list is empty' do
      @user.trainer_profile.update!(attack_team_ids: [@one.id])
      TeamRoster.update!(@user, role: :attack, user_pokemon_ids: [])

      assert_nil @user.trainer_profile.reload.attack_team_ids
    end
  end
end
