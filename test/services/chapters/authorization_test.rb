# frozen_string_literal: true

require 'test_helper'

module Chapters
  class AuthorizationTest < ActiveSupport::TestCase
    test 'new allowed for admin' do
      policy = Authorization.new(users(:user_one), fictions(:one))

      assert_predicate policy, :new?
    end

    test 'new allowed for scanlator member not yet on fiction' do
      policy = Authorization.new(users(:user_two), fictions(:one))

      assert_predicate policy, :new?
    end

    test 'new denied for user without scanlator membership' do
      policy = Authorization.new(User.find(101), fictions(:one))

      assert_not policy.new?
    end

    test 'new denied when fiction is missing' do
      policy = Authorization.new(users(:user_one), nil)

      assert_not policy.new?
    end

    test 'create allowed for admin without scanlator ids' do
      policy = Authorization.new(users(:user_one), fictions(:one))

      assert_predicate policy, :create?
    end

    test 'create allowed for fiction team member without scanlator ids' do
      policy = Authorization.new(users(:user_one), fictions(:one))

      assert_predicate policy, :create?
    end

    test 'create allowed for new team joining fiction with own scanlator id' do
      policy = Authorization.new(
        users(:user_two),
        fictions(:one),
        scanlator_ids: [scanlators(:two).id]
      )

      assert_predicate policy, :create?
    end

    test 'create denied for new team posting only foreign scanlator ids' do
      policy = Authorization.new(
        users(:user_two),
        fictions(:one),
        scanlator_ids: [scanlators(:one).id]
      )

      assert_not policy.create?
    end

    test 'create denied for team member without scanlator ids on unlinked fiction' do
      policy = Authorization.new(users(:user_two), fictions(:one))

      assert_not policy.create?
    end

    test 'create denied when fiction is missing' do
      policy = Authorization.new(users(:user_one), nil, scanlator_ids: [1])

      assert_not policy.create?
    end

    test 'create denied for user without scanlator membership' do
      policy = Authorization.new(User.find(101), fictions(:one), scanlator_ids: [scanlators(:one).id])

      assert_not policy.create?
    end
  end
end
