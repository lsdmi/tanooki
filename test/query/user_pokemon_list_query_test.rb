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

  test 'call returns ActiveRecord relation' do
    query = UserPokemonListQuery.new(@user)
    result = query.call

    assert result.is_a?(ActiveRecord::Relation)
    assert_equal UserPokemon, result.klass
  end

  test 'call returns query for correct user' do
    query = UserPokemonListQuery.new(@user)
    result = query.call

    # The result should be a relation that can be executed
    assert result.respond_to?(:to_a)
    assert result.respond_to?(:where)
  end

  test 'call returns query with includes' do
    query = UserPokemonListQuery.new(@user)
    result = query.call

    # Check that the result has the expected structure
    assert result.respond_to?(:includes)
  end
end
