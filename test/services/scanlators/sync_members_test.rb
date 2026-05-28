# frozen_string_literal: true

require 'test_helper'

module Scanlators
  class SyncMembersTest < ActiveSupport::TestCase
    setup do
      @scanlator = scanlators(:two)
      @member = users(:user_two)
      @other_user = users(:user_one)
    end

    test 'admin can add and remove members' do
      admin = users(:user_one)

      SyncMembers.new([@member.id, @other_user.id], @scanlator, user: admin).call

      assert_equal [@member.id, @other_user.id].sort, @scanlator.users.ids.sort
    end

    test 'team member can add and remove members' do
      SyncMembers.new([@member.id, @other_user.id], @scanlator, user: @member).call

      assert_equal [@member.id, @other_user.id].sort, @scanlator.users.ids.sort
    end

    test 'team member can remove themselves when another member remains' do
      ScanlatorUser.find_or_create_by!(scanlator: @scanlator, user: @other_user)

      SyncMembers.new([@other_user.id], @scanlator, user: @member).call

      assert_equal [@other_user.id], @scanlator.reload.users.ids
    end

    test 'non-member cannot change roster' do
      outsider = User.find(101) # users fixture id 101 — not on scanlators(:two)

      SyncMembers.new([@other_user.id], @scanlator, user: outsider).call

      assert_equal [@member.id], @scanlator.users.ids
    end

    test 'creator can set initial members on a new team' do
      @scanlator.scanlator_users.destroy_all

      SyncMembers.new([@member.id, @other_user.id], @scanlator, user: @member).call

      assert_equal [@member.id, @other_user.id].sort, @scanlator.users.ids.sort
    end

    test 'creator is added when only inviting another user on a new team' do
      @scanlator.scanlator_users.destroy_all

      SyncMembers.new([@other_user.id], @scanlator, user: @member, initial: true).call

      assert_equal [@member.id, @other_user.id].sort, @scanlator.users.ids.sort
    end
  end
end
