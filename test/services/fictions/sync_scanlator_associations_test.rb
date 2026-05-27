# frozen_string_literal: true

require 'test_helper'

module Fictions
  class SyncScanlatorAssociationsTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @scanlator_one = scanlators(:one)
      @scanlator_two = scanlators(:two)
      FictionScanlator.find_or_create_by!(fiction: @fiction, scanlator: @scanlator_two)
    end

    test 'non-admin save keeps scanlator teams not listed in the form' do
      user = users(:user_two)

      SyncScanlatorAssociations.new([@scanlator_two.id.to_s], @fiction, user: user).call

      assert_equal [@scanlator_one.id, @scanlator_two.id].sort, @fiction.scanlators.ids.sort
    end

    test 'non-admin can remove only their own team from the fiction' do
      user = users(:user_two)

      SyncScanlatorAssociations.new([], @fiction, user: user).call

      assert_equal [@scanlator_one.id], @fiction.scanlators.ids
    end

    test 'non-admin cannot assign a team they do not manage' do
      user = users(:user_two)
      @fiction.fiction_scanlators.where.not(scanlator: @scanlator_two).destroy_all

      SyncScanlatorAssociations.new([@scanlator_one.id.to_s], @fiction.reload, user: user).call

      assert_equal [@scanlator_two.id], @fiction.scanlators.ids
    end

    test 'admin save replaces the full scanlator list' do
      admin = users(:user_one)

      SyncScanlatorAssociations.new([@scanlator_two.id.to_s], @fiction, user: admin).call

      assert_equal [@scanlator_two.id], @fiction.scanlators.ids
    end
  end
end
