# frozen_string_literal: true

require 'test_helper'

module Scanlators
  class AuthorizationTest < ActiveSupport::TestCase
    test 'manage_members? is false without a user' do
      scanlator = scanlators(:one)

      assert_not Authorization.new(nil, scanlator).manage_members?
    end

    test 'manage_members? is true for admins' do
      scanlator = scanlators(:one)

      assert_predicate Authorization.new(users(:user_one), scanlator), :manage_members?
    end

    test 'manage_members? is true for new scanlator records' do
      user = users(:user_two)

      assert_predicate Authorization.new(user, Scanlator.new), :manage_members?
    end

    test 'manage_members? is true for scanlator members' do
      user = users(:user_one)
      scanlator = scanlators(:one)

      assert_predicate Authorization.new(user, scanlator), :manage_members?
    end

    test 'manage_members? is false for non-members' do
      user = users(:user_two)
      scanlator = scanlators(:one)

      assert_not Authorization.new(user, scanlator).manage_members?
    end
  end
end
