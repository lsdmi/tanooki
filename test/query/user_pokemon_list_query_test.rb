# frozen_string_literal: true

require 'test_helper'

class UserPokemonListQueryTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_one)
  end

  test 'initializes with user' do
    query = UserPokemonListQuery.new(@user)

    assert_equal @user, query.instance_variable_get(:@user)
  end

  test 'call returns a UserPokemon relation scoped to the user' do
    query = UserPokemonListQuery.new(@user)
    result = query.call

    assert_kind_of ActiveRecord::Relation, result
    assert_equal UserPokemon, result.klass
    assert_not result.where.not(user_id: @user.id).exists?
  end

  test 'call is executable and chainable' do
    query = UserPokemonListQuery.new(@user)
    result = query.call

    assert_respond_to result, :to_a
    assert_respond_to result, :where
    assert_respond_to result, :includes
  end

  test 'call preloads pokemon and sprite attachment' do
    result = UserPokemonListQuery.new(@user).call

    assert_includes result.includes_values, { pokemon: :sprite_attachment }
  end
end
